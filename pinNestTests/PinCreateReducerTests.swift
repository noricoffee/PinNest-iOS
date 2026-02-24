import ComposableArchitecture
import Foundation
import Testing

@Suite("PinCreateReducer")
@MainActor
struct PinCreateReducerTests {

    // MARK: - 入力フィールド変更

    @Test("titleChanged でタイトルが更新される")
    func titleChanged_updatesTitle() async {
        let store = TestStore(
            initialState: PinCreateReducer.State(mode: .create, contentType: .text)
        ) {
            PinCreateReducer()
        }

        await store.send(.titleChanged("My Title")) { state in
            state.title = "My Title"
        }
    }

    @Test("memoChanged でメモが更新される")
    func memoChanged_updatesMemo() async {
        let store = TestStore(
            initialState: PinCreateReducer.State(mode: .create, contentType: .url)
        ) {
            PinCreateReducer()
        }

        await store.send(.memoChanged("Some memo")) { state in
            state.memo = "Some memo"
        }
    }

    @Test("urlTextChanged で URL が更新される")
    func urlTextChanged_updatesUrlText() async {
        let store = TestStore(
            initialState: PinCreateReducer.State(mode: .create, contentType: .url)
        ) {
            PinCreateReducer()
        }

        await store.send(.urlTextChanged("https://example.com")) { state in
            state.urlText = "https://example.com"
        }
    }

    @Test("bodyTextChanged で本文が更新される")
    func bodyTextChanged_updatesBodyText() async {
        let store = TestStore(
            initialState: PinCreateReducer.State(mode: .create, contentType: .text)
        ) {
            PinCreateReducer()
        }

        await store.send(.bodyTextChanged("Hello, World!")) { state in
            state.bodyText = "Hello, World!"
        }
    }

    @Test("contentTypeChanged でタイプが変更され selectedFileName がリセットされる")
    func contentTypeChanged_resetsFileName() async {
        var initial = PinCreateReducer.State(mode: .create, contentType: .pdf)
        initial.selectedFileName = "document.pdf"

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        }

        await store.send(.contentTypeChanged(.image)) { state in
            state.contentType = .image
            state.selectedFileName = nil
        }
    }

    @Test("fileNameSelected でファイル名が設定される")
    func fileNameSelected_setsFileName() async {
        let store = TestStore(
            initialState: PinCreateReducer.State(mode: .create, contentType: .pdf)
        ) {
            PinCreateReducer()
        }

        await store.send(.fileNameSelected("report.pdf")) { state in
            state.selectedFileName = "report.pdf"
        }
    }

    // MARK: - effectiveTitle

    @Test("effectiveTitle: タイトル入力あり → そのまま使用")
    func effectiveTitle_usesInputTitleWhenPresent() {
        var state = PinCreateReducer.State(mode: .create, contentType: .url)
        state.title = "My Custom Title"
        state.urlText = "https://example.com"

        #expect(state.effectiveTitle == "My Custom Title")
    }

    @Test("effectiveTitle: URL タイプ + タイトル空欄 → URL を使用")
    func effectiveTitle_usesUrlWhenTitleEmpty() {
        var state = PinCreateReducer.State(mode: .create, contentType: .url)
        state.title = ""
        state.urlText = "https://example.com"

        #expect(state.effectiveTitle == "https://example.com")
    }

    @Test("effectiveTitle: テキストタイプ + タイトル空欄 → 本文の先頭 100 文字")
    func effectiveTitle_usesBodyTextPrefix() {
        var state = PinCreateReducer.State(mode: .create, contentType: .text)
        state.title = ""
        state.bodyText = "Short text"

        #expect(state.effectiveTitle == "Short text")
    }

    @Test("effectiveTitle: テキストタイプ + 本文が 100 文字超 → 先頭 100 文字のみ")
    func effectiveTitle_truncatesBodyTextAt100Chars() {
        var state = PinCreateReducer.State(mode: .create, contentType: .text)
        state.title = ""
        state.bodyText = String(repeating: "a", count: 150)

        #expect(state.effectiveTitle.count == 100)
    }

    // MARK: - saveButtonTapped（作成モード: テキスト）

    @Test("テキストピンの保存: PinClient.create が呼ばれる")
    func saveButtonTapped_createText_callsPinClient() async {
        var initial = PinCreateReducer.State(mode: .create, contentType: .text)
        initial.title = "My Note"
        initial.bodyText = "Note content"

        // @Sendable クロージャ内での var capture を避けるため参照型を使用
        final class Captured: @unchecked Sendable { var pin: NewPin? }
        let captured = Captured()

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        } withDependencies: {
            $0.pinClient.create = { pin in captured.pin = pin }
        }

        await store.send(.saveButtonTapped) { state in
            state.isSaving = true
            state.saveError = nil
        }

        await store.receive(\.saveResponse) { state in
            state.isSaving = false
        }

        #expect(captured.pin?.contentType == .text)
        #expect(captured.pin?.title == "My Note")
        #expect(captured.pin?.bodyText == "Note content")
    }

    // MARK: - saveButtonTapped（作成モード: URL）

    @Test("URL ピンの保存: MetadataClient.fetch が呼ばれ PinClient.create が実行される")
    func saveButtonTapped_createUrl_callsMetadataAndPinClient() async {
        var initial = PinCreateReducer.State(mode: .create, contentType: .url)
        initial.urlText = "https://example.com"

        // @Sendable クロージャ内での var capture を避けるため参照型を使用
        final class Captured: @unchecked Sendable { var url: URL?; var pin: NewPin? }
        let captured = Captured()

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        } withDependencies: {
            $0.metadataClient.fetch = { url in
                captured.url = url
                return URLMetadata(title: "Example Domain", thumbnailData: nil, faviconData: nil)
            }
            $0.pinClient.create = { pin in captured.pin = pin }
        }

        await store.send(.saveButtonTapped) { state in
            state.isSaving = true
            state.saveError = nil
        }

        await store.receive(\.saveResponse) { state in
            state.isSaving = false
        }

        #expect(captured.url?.absoluteString == "https://example.com")
        #expect(captured.pin?.contentType == .url)
        // OG タイトルが優先される
        #expect(captured.pin?.title == "Example Domain")
        #expect(captured.pin?.urlString == "https://example.com")
    }

    @Test("URL が空の場合は MetadataClient を呼ばない")
    func saveButtonTapped_emptyUrl_skipsMetadata() async {
        let initial = PinCreateReducer.State(mode: .create, contentType: .url)
        // urlText は空

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        } withDependencies: {
            $0.pinClient.create = { _ in }
        }

        await store.send(.saveButtonTapped) { state in
            state.isSaving = true
            state.saveError = nil
        }

        await store.receive(\.saveResponse) { state in
            state.isSaving = false
        }
    }

    // MARK: - saveButtonTapped（編集モード）

    @Test("編集モードで保存すると PinClient.update が呼ばれる")
    func saveButtonTapped_editMode_callsUpdate() async {
        let existingPin = Pin(
            id: UUID(),
            contentType: .text,
            title: "Old Title",
            memo: "Old memo",
            bodyText: "Old body"
        )

        var initial = PinCreateReducer.State(mode: .edit(existingPin), contentType: .text)
        initial.title = "New Title"
        initial.memo = "New memo"
        initial.bodyText = "New body"

        // @Sendable クロージャ内での var capture を避けるため参照型を使用
        final class Captured: @unchecked Sendable { var id: UUID?; var title: String? }
        let captured = Captured()

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        } withDependencies: {
            $0.pinClient.update = { id, title, _, _, _, _, _ in
                captured.id = id
                captured.title = title
            }
        }

        await store.send(.saveButtonTapped) { state in
            state.isSaving = true
            state.saveError = nil
        }

        await store.receive(\.saveResponse) { state in
            state.isSaving = false
        }

        #expect(captured.id == existingPin.id)
        #expect(captured.title == "New Title")
    }

    // MARK: - saveResponse

    @Test("保存成功で isSaving が false になる")
    func saveResponse_success_clearsSaving() async {
        var initial = PinCreateReducer.State(mode: .create, contentType: .text)
        initial.isSaving = true

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        }

        await store.send(.saveResponse(.success(()))) { state in
            state.isSaving = false
        }
    }

    @Test("保存失敗で isSaving が false になり saveError が設定される")
    func saveResponse_failure_setsError() async {
        var initial = PinCreateReducer.State(mode: .create, contentType: .text)
        initial.isSaving = true

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        }

        struct SaveError: Error, LocalizedError {
            var errorDescription: String? { "Save failed" }
        }

        await store.send(.saveResponse(.failure(SaveError()))) { state in
            state.isSaving = false
            state.saveError = "Save failed"
        }
    }

    // MARK: - isSaving ガード

    @Test("isSaving 中は saveButtonTapped を無視する")
    func saveButtonTapped_ignored_whileSaving() async {
        var initial = PinCreateReducer.State(mode: .create, contentType: .text)
        initial.isSaving = true

        let store = TestStore(initialState: initial) {
            PinCreateReducer()
        }

        await store.send(.saveButtonTapped)
    }
}

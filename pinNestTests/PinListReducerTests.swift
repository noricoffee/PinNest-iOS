import ComposableArchitecture
import Foundation
import Testing

@Suite("PinListReducer")
@MainActor
struct PinListReducerTests {

    // MARK: - onAppear

    @Test("初回 onAppear でピンを取得する")
    func onAppear_fetchesPinsWhenEmpty() async {
        let pin1 = Pin(
            id: UUID(),
            contentType: .url,
            title: "Newer Pin",
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let pin2 = Pin(
            id: UUID(),
            contentType: .text,
            title: "Older Pin",
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let store = TestStore(initialState: PinListReducer.State()) {
            PinListReducer()
        } withDependencies: {
            $0.pinClient.fetchAll = { [pin1, pin2] }
        }

        await store.send(.onAppear) { state in
            state.isLoading = true
        }

        // 新しい順（pin1: 2000 > pin2: 1000）に並ぶことを確認
        await store.receive(\.pinsResponse) { state in
            state.isLoading = false
            state.pins = [pin1, pin2]
        }
    }

    @Test("ピンがある場合の onAppear は何もしない")
    func onAppear_skipsWhenPinsAlreadyLoaded() async {
        let pin = Pin(contentType: .url, title: "Existing")
        var initial = PinListReducer.State()
        initial.pins = [pin]

        let store = TestStore(initialState: initial) {
            PinListReducer()
        }

        await store.send(.onAppear)
    }

    // MARK: - refresh

    @Test("refresh は常にピンを再取得する")
    func refresh_fetchesPins() async {
        let pin = Pin(id: UUID(), contentType: .text, title: "Refreshed")

        let store = TestStore(initialState: PinListReducer.State()) {
            PinListReducer()
        } withDependencies: {
            $0.pinClient.fetchAll = { [pin] }
        }

        await store.send(.refresh) { state in
            state.isLoading = true
        }

        await store.receive(\.pinsResponse) { state in
            state.isLoading = false
            state.pins = [pin]
        }
    }

    // MARK: - filterSelected

    @Test("filterSelected でフィルターが変更される")
    func filterSelected_updatesFilter() async {
        let store = TestStore(initialState: PinListReducer.State()) {
            PinListReducer()
        }

        await store.send(.filterSelected(.url)) { state in
            state.selectedFilter = .url
        }

        await store.send(.filterSelected(.text)) { state in
            state.selectedFilter = .text
        }

        await store.send(.filterSelected(nil)) { state in
            state.selectedFilter = nil
        }
    }

    // MARK: - filteredPins

    @Test("filteredPins はフィルター条件で絞り込む")
    func filteredPins_filtersByContentType() {
        let urlPin = Pin(id: UUID(), contentType: .url, title: "URL Pin")
        let textPin = Pin(id: UUID(), contentType: .text, title: "Text Pin")
        var state = PinListReducer.State()
        state.pins = [urlPin, textPin]

        #expect(state.filteredPins.count == 2)

        state.selectedFilter = .url
        #expect(state.filteredPins.count == 1)
        #expect(state.filteredPins.first?.id == urlPin.id)

        state.selectedFilter = .text
        #expect(state.filteredPins.count == 1)
        #expect(state.filteredPins.first?.id == textPin.id)
    }

    // MARK: - pinsResponse failure

    @Test("pinsResponse 失敗時に isLoading が false になる")
    func pinsResponse_failure_clearsLoading() async {
        var initial = PinListReducer.State()
        initial.isLoading = true

        let store = TestStore(initialState: initial) {
            PinListReducer()
        }

        struct FetchError: Error {}
        await store.send(.pinsResponse(.failure(FetchError()))) { state in
            state.isLoading = false
        }
    }

    // MARK: - pinsResponse sorting

    @Test("pinsResponse で新しい順に並び替えられる")
    func pinsResponse_sortsByCreatedAtDescending() async {
        let older = Pin(
            id: UUID(),
            contentType: .url,
            title: "Older",
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let newer = Pin(
            id: UUID(),
            contentType: .url,
            title: "Newer",
            createdAt: Date(timeIntervalSince1970: 9000)
        )

        // fetchAll が古い順（older, newer）で返す
        let store = TestStore(initialState: PinListReducer.State()) {
            PinListReducer()
        } withDependencies: {
            $0.pinClient.fetchAll = { [older, newer] }
        }

        await store.send(.onAppear) { state in
            state.isLoading = true
        }

        // newer が先に来るよう並び替えられることを確認
        await store.receive(\.pinsResponse) { state in
            state.isLoading = false
            state.pins = [newer, older]
        }
    }

    // MARK: - pinTapped

    @Test("pinTapped で詳細が表示される")
    func pinTapped_setsDetailState() async {
        let pin = Pin(id: UUID(), contentType: .url, title: "Test Pin", urlString: "https://example.com")
        var initial = PinListReducer.State()
        initial.pins = [pin]

        let store = TestStore(initialState: initial) {
            PinListReducer()
        } withDependencies: {
            $0.pinClient.fetchTagsForPin = { _ in [] }
        }

        await store.send(.pinTapped(pin)) { state in
            state.detail = PinDetailReducer.State(pin: pin)
        }
    }
}

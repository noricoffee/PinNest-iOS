import ComposableArchitecture
import Foundation
import Testing

@Suite("SearchReducer")
@MainActor
struct SearchReducerTests {

    // MARK: - onAppear

    @Test("onAppear でタグ一覧を取得する")
    func onAppear_fetchesTags() async {
        let tag = TagItem(id: UUID(), name: "Swift")

        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.fetchAllTags = { [tag] }
        }

        await store.send(.onAppear)

        await store.receive(\.tagsResponse) { state in
            state.allTags = [tag]
        }
    }

    @Test("onAppear でタグ取得に失敗しても状態は変わらない")
    func onAppear_tagsFailure_noStateChange() async {
        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        } withDependencies: {
            struct FetchError: Error {}
            $0.pinClient.fetchAllTags = { throw FetchError() }
        }

        await store.send(.onAppear)

        await store.receive(\.tagsResponse)
        // tagsResponse(.failure) の場合は state は変わらない
    }

    // MARK: - searchTextChanged

    @Test("空の検索テキストで結果をクリアし hasSearched が false になる")
    func searchTextChanged_empty_clearsResults() async {
        var initial = SearchReducer.State()
        initial.searchText = "previous query"
        initial.results = [Pin(contentType: .url, title: "Old Result")]
        initial.hasSearched = true
        initial.isLoading = false

        let store = TestStore(initialState: initial) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.fetchAllTags = { [] }
        }

        await store.send(.searchTextChanged("")) { state in
            state.searchText = ""
            state.hasSearched = false
            state.results = []
            state.isLoading = false
        }
    }

    @Test("検索テキスト変更で検索が実行され結果が更新される")
    func searchTextChanged_withQuery_triggersSearchAndUpdatesResults() async {
        let pin = Pin(id: UUID(), contentType: .url, title: "Swift Tutorial")

        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.search = { _, _, _ in [pin] }
        }

        await store.send(.searchTextChanged("Swift")) { state in
            state.searchText = "Swift"
            state.hasSearched = true
            state.isLoading = true
        }

        // 300ms デバウンス後に searchResponse が届く
        await store.receive(\.searchResponse) { state in
            state.isLoading = false
            state.results = [pin]
        }
    }

    @Test("検索テキスト変更で前のリクエストがキャンセルされる")
    func searchTextChanged_cancelsPreviousRequest() async {
        let pin = Pin(id: UUID(), contentType: .text, title: "Final Result")

        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.search = { _, _, _ in [pin] }
        }

        // 最初の検索（キャンセルされる）
        await store.send(.searchTextChanged("a")) { state in
            state.searchText = "a"
            state.hasSearched = true
            state.isLoading = true
        }

        // 即座に次の検索（前の検索をキャンセル）
        await store.send(.searchTextChanged("ab")) { state in
            state.searchText = "ab"
        }

        // 最終的な結果のみ届く
        await store.receive(\.searchResponse) { state in
            state.isLoading = false
            state.results = [pin]
        }
    }

    // MARK: - tagFilterToggled

    @Test("tagFilterToggled でタグが選択・解除される")
    func tagFilterToggled_togglesTagSelection() async {
        let tagID = UUID()

        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.search = { _, _, _ in [] }
        }

        // タグを選択 → 検索が走る
        await store.send(.tagFilterToggled(tagID)) { state in
            state.selectedTagIds = [tagID]
            state.hasSearched = true
            state.isLoading = true
        }

        await store.receive(\.searchResponse) { state in
            state.isLoading = false
        }

        // タグを解除 → 選択がなくなると hasSearched = false に
        await store.send(.tagFilterToggled(tagID)) { state in
            state.selectedTagIds = []
            state.hasSearched = false
        }
    }

    @Test("タグ選択時に検索が実行される")
    func tagFilterToggled_withTag_triggersSearch() async {
        let tagID = UUID()
        let pin = Pin(id: UUID(), contentType: .image, title: "Tagged Pin")

        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.search = { _, tagIds, _ in
                tagIds.contains(tagID) ? [pin] : []
            }
        }

        await store.send(.tagFilterToggled(tagID)) { state in
            state.selectedTagIds = [tagID]
            state.hasSearched = true
            state.isLoading = true
        }

        await store.receive(\.searchResponse) { state in
            state.isLoading = false
            state.results = [pin]
        }
    }

    // MARK: - sortOrderChanged

    @Test("sortOrderChanged でソート順が変更される")
    func sortOrderChanged_updatesSortOrder() async {
        let store = TestStore(initialState: SearchReducer.State()) {
            SearchReducer()
        }

        // hasSearched = false の場合は検索しない
        await store.send(.sortOrderChanged(.oldestFirst)) { state in
            state.sortOrder = .oldestFirst
        }
    }

    @Test("検索中に sortOrderChanged すると再検索される")
    func sortOrderChanged_whenSearched_retriggersSearch() async {
        let pin = Pin(id: UUID(), contentType: .url, title: "Pin A")
        var initial = SearchReducer.State()
        initial.searchText = "test"
        initial.hasSearched = true
        initial.results = [pin]

        let store = TestStore(initialState: initial) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.search = { _, _, _ in [pin] }
        }

        await store.send(.sortOrderChanged(.oldestFirst)) { state in
            state.sortOrder = .oldestFirst
            state.isLoading = true
        }

        await store.receive(\.searchResponse) { state in
            state.isLoading = false
            state.results = [pin]
        }
    }

    // MARK: - searchResponse

    @Test("searchResponse 成功で結果が更新される")
    func searchResponse_success_updatesResults() async {
        let pin = Pin(id: UUID(), contentType: .url, title: "Found Pin")
        var initial = SearchReducer.State()
        initial.isLoading = true

        let store = TestStore(initialState: initial) {
            SearchReducer()
        }

        await store.send(.searchResponse(.success([pin]))) { state in
            state.isLoading = false
            state.results = [pin]
        }
    }

    @Test("searchResponse 失敗で isLoading が false になる")
    func searchResponse_failure_clearsLoading() async {
        var initial = SearchReducer.State()
        initial.isLoading = true

        let store = TestStore(initialState: initial) {
            SearchReducer()
        }

        struct SearchError: Error {}
        await store.send(.searchResponse(.failure(SearchError()))) { state in
            state.isLoading = false
        }
    }

    // MARK: - pinTapped

    @Test("pinTapped で詳細が表示される")
    func pinTapped_setsDetailState() async {
        let pin = Pin(id: UUID(), contentType: .text, title: "Detail Pin")
        var initial = SearchReducer.State()
        initial.results = [pin]

        let store = TestStore(initialState: initial) {
            SearchReducer()
        } withDependencies: {
            $0.pinClient.fetchTagsForPin = { _ in [] }
        }

        await store.send(.pinTapped(pin)) { state in
            state.detail = PinDetailReducer.State(pin: pin)
        }
    }
}

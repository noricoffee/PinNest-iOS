import ComposableArchitecture
import Foundation

@Reducer
struct SearchReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var searchText: String = ""
        var selectedTagIds: Set<UUID> = []
        var sortOrder: PinSortOrder = .newestFirst
        var results: [Pin] = []
        var allTags: [TagItem] = []
        var isLoading: Bool = false
        /// キーワードまたはタグフィルターが一度でも指定されたかどうか
        var hasSearched: Bool = false
        @Presents var detail: PinDetailReducer.State? = nil

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.searchText == rhs.searchText &&
            lhs.selectedTagIds == rhs.selectedTagIds &&
            lhs.sortOrder == rhs.sortOrder &&
            lhs.results.map(\.id) == rhs.results.map(\.id) &&
            lhs.results.map(\.isFavorite) == rhs.results.map(\.isFavorite) &&
            lhs.allTags == rhs.allTags &&
            lhs.isLoading == rhs.isLoading &&
            lhs.hasSearched == rhs.hasSearched &&
            lhs.detail == rhs.detail
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case searchTextChanged(String)
        case tagFilterToggled(UUID)
        case sortOrderChanged(PinSortOrder)
        case searchResponse(Result<[Pin], Error>)
        case tagsResponse(Result<[TagItem], Error>)
        case pinTapped(Pin)
        case detail(PresentationAction<PinDetailReducer.Action>)
    }

    private enum CancelID { case search }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
            @Dependency(\.analyticsClient) var analyticsClient
            @Dependency(\.crashlyticsClient) var crashlyticsClient
            switch action {

            case .onAppear:
                return .run { send in
                    await send(.tagsResponse(Result {
                        try await pinClient.fetchAllTags()
                    }))
                }

            case let .searchTextChanged(text):
                state.searchText = text
                let hasQuery = !text.isEmpty || !state.selectedTagIds.isEmpty
                state.hasSearched = hasQuery
                guard hasQuery else {
                    state.results = []
                    state.isLoading = false
                    return .cancel(id: CancelID.search)
                }
                state.isLoading = true
                let tagIds = state.selectedTagIds
                let sortOrder = state.sortOrder
                return .run { send in
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.searchResponse(Result {
                        try await pinClient.search(text, tagIds, sortOrder)
                    }))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case let .tagFilterToggled(tagId):
                if state.selectedTagIds.contains(tagId) {
                    state.selectedTagIds.remove(tagId)
                } else {
                    state.selectedTagIds.insert(tagId)
                }
                let hasQuery = !state.searchText.isEmpty || !state.selectedTagIds.isEmpty
                state.hasSearched = hasQuery
                guard hasQuery else {
                    state.results = []
                    return .none
                }
                state.isLoading = true
                let text = state.searchText
                let tagIds = state.selectedTagIds
                let sortOrder = state.sortOrder
                return .run { send in
                    await send(.searchResponse(Result {
                        try await pinClient.search(text, tagIds, sortOrder)
                    }))
                }

            case let .sortOrderChanged(order):
                state.sortOrder = order
                guard state.hasSearched else { return .none }
                state.isLoading = true
                let text = state.searchText
                let tagIds = state.selectedTagIds
                return .run { send in
                    await send(.searchResponse(Result {
                        try await pinClient.search(text, tagIds, order)
                    }))
                }

            case let .searchResponse(.success(pins)):
                state.isLoading = false
                state.results = pins
                analyticsClient.logEvent(.searchPerformed(
                    hasKeyword: !state.searchText.isEmpty,
                    hasTagFilter: !state.selectedTagIds.isEmpty,
                    sortOrder: state.sortOrder.rawValue
                ))
                return .none

            case let .searchResponse(.failure(error)):
                state.isLoading = false
                crashlyticsClient.recordError(error, "PinClient.search")
                return .none

            case let .tagsResponse(.success(tags)):
                state.allTags = tags
                return .none

            case .tagsResponse(.failure):
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
                return .none

            case .detail(.presented(.deleteResponse(.success))):
                state.detail = nil
                guard state.hasSearched else { return .none }
                let text = state.searchText
                let tagIds = state.selectedTagIds
                let sortOrder = state.sortOrder
                return .run { send in
                    await send(.searchResponse(Result {
                        try await pinClient.search(text, tagIds, sortOrder)
                    }))
                }

            case .detail(.presented(.favoriteResponse(.success))):
                if let updatedPin = state.detail?.pin,
                   let idx = state.results.firstIndex(where: { $0.id == updatedPin.id }) {
                    state.results[idx].isFavorite = updatedPin.isFavorite
                }
                return .none

            case .detail(.dismiss):
                // タグ変更後に検索結果を更新する
                guard state.hasSearched else { return .none }
                let text = state.searchText
                let tagIds = state.selectedTagIds
                let sortOrder = state.sortOrder
                return .run { send in
                    await send(.searchResponse(Result {
                        try await pinClient.search(text, tagIds, sortOrder)
                    }))
                }

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            PinDetailReducer()
        }
    }
}

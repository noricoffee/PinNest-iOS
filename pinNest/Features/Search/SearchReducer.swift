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
        var errorMessage: String? = nil
        @Presents var detail: PinDetailReducer.State? = nil
        var contextMenu: PinContextMenuReducer.State = .init()

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.searchText == rhs.searchText &&
            lhs.selectedTagIds == rhs.selectedTagIds &&
            lhs.sortOrder == rhs.sortOrder &&
            lhs.results.map(\.id) == rhs.results.map(\.id) &&
            lhs.results.map(\.isFavorite) == rhs.results.map(\.isFavorite) &&
            lhs.allTags == rhs.allTags &&
            lhs.isLoading == rhs.isLoading &&
            lhs.detail == rhs.detail &&
            lhs.contextMenu == rhs.contextMenu
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case refresh
        case searchTextChanged(String)
        case tagFilterToggled(UUID)
        case sortOrderChanged(PinSortOrder)
        case searchResponse(Result<[Pin], Error>)
        case tagsResponse(Result<[TagItem], Error>)
        case pinTapped(Pin)
        case errorAlertDismissed
        case detail(PresentationAction<PinDetailReducer.Action>)
        case contextMenu(PinContextMenuReducer.Action)
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
                return .send(.refresh)

            case .refresh:
                state.isLoading = true
                let refreshText = state.searchText
                let refreshTagIds = state.selectedTagIds
                let refreshSortOrder = state.sortOrder
                return .run { send in
                    let tagsResult = await Result<[TagItem], Error> { try await pinClient.fetchAllTags() }
                    await send(.tagsResponse(tagsResult))
                    await send(.searchResponse(Result {
                        try await pinClient.search(refreshText, refreshTagIds, refreshSortOrder)
                    }))
                }

            case let .searchTextChanged(text):
                state.searchText = text
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
                state.errorMessage = error.localizedDescription
                crashlyticsClient.recordError(error, "PinClient.search")
                return .none

            case .errorAlertDismissed:
                state.errorMessage = nil
                return .none

            case let .tagsResponse(.success(tags)):
                state.allTags = [.favorite] + tags
                return .none

            case .tagsResponse(.failure):
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
                return .none

            case .detail(.presented(.deleteResponse(.success))):
                return searchEffect(state: state)

            case .detail(.presented(.favoriteResponse(.success))):
                if let updatedPin = state.detail?.pin,
                   let idx = state.results.firstIndex(where: { $0.id == updatedPin.id }) {
                    state.results[idx].isFavorite = updatedPin.isFavorite
                }
                return .none

            case .detail(.dismiss):
                return searchEffect(state: state)

            case .detail:
                return .none

            // MARK: - Context Menu (親インターセプト)

            case .contextMenu(.deleteResponse(.success)):
                return searchEffect(state: state)

            case .contextMenu(.tagPicker(.dismiss)):
                return searchEffect(state: state)

            case .contextMenu:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            PinDetailReducer()
        }

        Scope(state: \.contextMenu, action: \.contextMenu) {
            PinContextMenuReducer()
        }
    }

    // MARK: - Helpers

    private func searchEffect(state: State) -> Effect<Action> {
        @Dependency(\.pinClient) var pinClient
        let text = state.searchText
        let tagIds = state.selectedTagIds
        let sortOrder = state.sortOrder
        return .run { send in
            await send(.searchResponse(Result {
                try await pinClient.search(text, tagIds, sortOrder)
            }))
        }
    }
}

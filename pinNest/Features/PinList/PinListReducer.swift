import ComposableArchitecture
import Foundation

@Reducer
struct PinListReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var pins: [Pin] = []
        var selectedFilter: ContentType? = nil
        var isLoading: Bool = false
        var errorMessage: String? = nil
        @Presents var detail: PinDetailReducer.State? = nil
        var contextMenu: PinContextMenuReducer.State = .init()

        var filteredPins: [Pin] {
            guard let filter = selectedFilter else { return pins }
            return pins.filter { $0.contentType == filter }
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.pins.map(\.id) == rhs.pins.map(\.id) &&
            lhs.pins.map(\.isFavorite) == rhs.pins.map(\.isFavorite) &&
            lhs.selectedFilter == rhs.selectedFilter &&
            lhs.isLoading == rhs.isLoading &&
            lhs.detail == rhs.detail &&
            lhs.contextMenu == rhs.contextMenu
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case refresh
        case pinsResponse(Result<[Pin], Error>)
        case filterSelected(ContentType?)
        case pinTapped(Pin)
        case favoriteButtonTapped(Pin)
        case favoriteResponse(Result<Void, Error>)
        case settingsButtonTapped
        case errorAlertDismissed
        case detail(PresentationAction<PinDetailReducer.Action>)
        case contextMenu(PinContextMenuReducer.Action)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
            @Dependency(\.analyticsClient) var analyticsClient
            @Dependency(\.crashlyticsClient) var crashlyticsClient
            @Dependency(\.hapticClient) var hapticClient
            switch action {

            case .onAppear:
                guard state.pins.isEmpty else { return .none }
                return .send(.refresh)

            case .refresh:
                state.isLoading = true
                return .run { send in
                    await send(.pinsResponse(Result {
                        try await pinClient.fetchAll()
                    }))
                }

            case let .pinsResponse(.success(pins)):
                state.isLoading = false
                state.pins = pins.sorted { $0.createdAt > $1.createdAt }
                return .none

            case let .pinsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .errorAlertDismissed:
                state.errorMessage = nil
                return .none

            case let .filterSelected(filter):
                state.selectedFilter = filter
                hapticClient.selection()
                analyticsClient.logEvent(.filterApplied(contentType: filter?.rawValue))
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
                return .none

            case let .favoriteButtonTapped(pin):
                guard let idx = state.pins.firstIndex(where: { $0.id == pin.id }) else { return .none }
                state.pins[idx].isFavorite.toggle()
                hapticClient.impact(.medium)
                let id = state.pins[idx].id
                let isFavorite = state.pins[idx].isFavorite
                return .run { send in
                    await send(.favoriteResponse(Result {
                        try await pinClient.updateFavorite(id, isFavorite)
                    }))
                }

            case .favoriteResponse(.success):
                return .none

            case let .favoriteResponse(.failure(error)):
                crashlyticsClient.recordError(error, "PinClient.update.favorite")
                return .send(.refresh)

            case .settingsButtonTapped:
                return .none

            case .detail(.presented(.deleteResponse(.success))):
                return .send(.refresh)

            case .detail(.presented(.favoriteResponse(.success))):
                if let updatedPin = state.detail?.pin,
                   let idx = state.pins.firstIndex(where: { $0.id == updatedPin.id }) {
                    state.pins[idx].isFavorite = updatedPin.isFavorite
                }
                return .none

            case .detail:
                return .none

            // MARK: - Context Menu (親インターセプト)

            case .contextMenu(.deleteResponse(.success)):
                return .send(.refresh)

            case .contextMenu(.tagPicker(.dismiss)):
                return .send(.refresh)

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
}

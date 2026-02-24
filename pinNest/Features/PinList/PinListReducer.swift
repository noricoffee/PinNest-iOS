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
        @Presents var detail: PinDetailReducer.State? = nil

        var filteredPins: [Pin] {
            guard let filter = selectedFilter else { return pins }
            return pins.filter { $0.contentType == filter }
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.pins.map(\.id) == rhs.pins.map(\.id) &&
            lhs.pins.map(\.isFavorite) == rhs.pins.map(\.isFavorite) &&
            lhs.selectedFilter == rhs.selectedFilter &&
            lhs.isLoading == rhs.isLoading &&
            lhs.detail == rhs.detail
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case refresh
        case pinsResponse(Result<[Pin], Error>)
        case filterSelected(ContentType?)
        case pinTapped(Pin)
        case settingsButtonTapped
        case detail(PresentationAction<PinDetailReducer.Action>)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
            switch action {

            case .onAppear:
                guard state.pins.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    await send(.pinsResponse(Result {
                        try await pinClient.fetchAll()
                    }))
                }

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

            case .pinsResponse(.failure):
                state.isLoading = false
                return .none

            case let .filterSelected(filter):
                state.selectedFilter = filter
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
                return .none

            case .settingsButtonTapped:
                return .none

            case .detail(.presented(.deleteResponse(.success))):
                state.detail = nil
                return .send(.refresh)

            case .detail(.presented(.favoriteResponse(.success))):
                // リスト内の該当ピンも更新
                if let updatedPin = state.detail?.pin,
                   let idx = state.pins.firstIndex(where: { $0.id == updatedPin.id }) {
                    state.pins[idx].isFavorite = updatedPin.isFavorite
                }
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            PinDetailReducer()
        }
    }
}

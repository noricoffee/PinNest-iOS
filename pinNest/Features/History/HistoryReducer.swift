import ComposableArchitecture
import Foundation

@Reducer
struct HistoryReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var pins: [Pin] = []
        var isLoading: Bool = false
        @Presents var detail: PinDetailReducer.State? = nil

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.pins.map(\.id) == rhs.pins.map(\.id) &&
            lhs.isLoading == rhs.isLoading &&
            lhs.detail == rhs.detail
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case refresh
        case pinsResponse(Result<[Pin], Error>)
        case pinTapped(Pin)
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
                // タイムラインは古い順（上が過去・下が最新）
                state.pins = pins.sorted { $0.createdAt < $1.createdAt }
                return .none

            case .pinsResponse(.failure):
                state.isLoading = false
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
                return .none

            case .detail(.presented(.deleteResponse(.success))):
                // dismiss は PinDetailReducer 側で即座に処理される
                return .send(.refresh)

            case .detail(.presented(.favoriteResponse(.success))):
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

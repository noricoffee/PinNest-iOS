import ComposableArchitecture
import Foundation

@Reducer
struct HistoryReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var pins: [Pin] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
        @Presents var detail: PinDetailReducer.State? = nil
        var contextMenu: PinContextMenuReducer.State = .init()

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.pins.map(\.id) == rhs.pins.map(\.id) &&
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
        case pinTapped(Pin)
        case errorAlertDismissed
        case detail(PresentationAction<PinDetailReducer.Action>)
        case contextMenu(PinContextMenuReducer.Action)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
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
                // タイムラインは古い順（上が過去・下が最新）
                state.pins = pins.sorted { $0.createdAt < $1.createdAt }
                return .none

            case .pinsResponse(.failure):
                state.isLoading = false
                state.errorMessage = "データの読み込みに失敗しました。"
                return .none

            case .errorAlertDismissed:
                state.errorMessage = nil
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
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

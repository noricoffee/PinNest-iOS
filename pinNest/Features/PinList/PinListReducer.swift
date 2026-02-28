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
        case favoriteButtonTapped(Pin)
        case favoriteResponse(Result<Void, Error>)
        case settingsButtonTapped
        case detail(PresentationAction<PinDetailReducer.Action>)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
            @Dependency(\.analyticsClient) var analyticsClient
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
                analyticsClient.logEvent(.filterApplied(contentType: filter?.rawValue))
                return .none

            case let .pinTapped(pin):
                state.detail = PinDetailReducer.State(pin: pin)
                return .none

            case let .favoriteButtonTapped(pin):
                guard let idx = state.pins.firstIndex(where: { $0.id == pin.id }) else { return .none }
                state.pins[idx].isFavorite.toggle()
                let updated = state.pins[idx]
                return .run { send in
                    await send(.favoriteResponse(Result {
                        try await pinClient.update(
                            updated.id,
                            updated.title,
                            updated.memo,
                            updated.isFavorite,
                            updated.urlString,
                            updated.filePath,
                            updated.bodyText
                        )
                    }))
                }

            case .favoriteResponse(.success):
                return .none

            case let .favoriteResponse(.failure(error)):
                // 楽観的更新を元に戻す（再取得で確実にリストを同期）
                return .send(.refresh)

            case .settingsButtonTapped:
                return .none

            case .detail(.presented(.deleteResponse(.success))):
                // dismiss は PinDetailReducer 側で即座に処理される
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

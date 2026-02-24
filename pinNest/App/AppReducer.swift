import ComposableArchitecture

@Reducer
struct AppReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var isFABExpanded: Bool = false
        var pinList: PinListReducer.State = .init()
        var search: SearchReducer.State = .init()
        @Presents var pinCreate: PinCreateReducer.State? = nil
    }

    // MARK: - Tab

    enum Tab: Hashable {
        case home, history, search
    }

    // MARK: - Action

    enum Action {
        case tabSelected(Tab)
        case fabButtonTapped
        case fabMenuItemTapped(ContentType)
        case overlayTapped
        case pinList(PinListReducer.Action)
        case search(SearchReducer.Action)
        case create(PresentationAction<PinCreateReducer.Action>)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .fabButtonTapped:
                state.isFABExpanded.toggle()
                return .none

            case let .fabMenuItemTapped(type):
                state.isFABExpanded = false
                state.pinCreate = PinCreateReducer.State(contentType: type)
                return .none

            case .overlayTapped:
                state.isFABExpanded = false
                return .none

            case let .pinList(listAction):
                // 詳細画面の「編集」ボタン → PinCreate シートを開く
                if case .detail(.presented(.editButtonTapped)) = listAction,
                   let pin = state.pinList.detail?.pin {
                    state.pinList.detail = nil
                    state.pinCreate = PinCreateReducer.State(mode: .edit(pin), contentType: pin.contentType)
                }
                return .none

            case let .search(searchAction):
                // 検索画面の詳細から「編集」ボタン → PinCreate シートを開く
                if case .detail(.presented(.editButtonTapped)) = searchAction,
                   let pin = state.search.detail?.pin {
                    state.search.detail = nil
                    state.pinCreate = PinCreateReducer.State(mode: .edit(pin), contentType: pin.contentType)
                }
                return .none

            case .create(.presented(.saveResponse(.success))):
                state.pinCreate = nil
                return .send(.pinList(.refresh))

            case .create(.presented(.cancelButtonTapped)):
                state.pinCreate = nil
                return .none

            case .create:
                return .none
            }
        }
        .ifLet(\.$pinCreate, action: \.create) {
            PinCreateReducer()
        }

        Scope(state: \.pinList, action: \.pinList) {
            PinListReducer()
        }

        Scope(state: \.search, action: \.search) {
            SearchReducer()
        }
    }
}

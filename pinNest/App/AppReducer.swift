import ComposableArchitecture

@Reducer
struct AppReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var isFABExpanded: Bool = false
        var createContentType: PinContentType? = nil
    }

    // MARK: - Tab

    enum Tab: Hashable {
        case home, history, search
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case tabSelected(Tab)
        case fabButtonTapped
        case fabMenuItemTapped(PinContentType)
        case overlayTapped
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .fabButtonTapped:
                state.isFABExpanded.toggle()
                return .none

            case let .fabMenuItemTapped(type):
                state.isFABExpanded = false
                state.createContentType = type
                return .none

            case .overlayTapped:
                state.isFABExpanded = false
                return .none
            }
        }
    }
}

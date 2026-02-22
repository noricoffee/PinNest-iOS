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

    enum Action {
        case tabSelected(Tab)
        case fabButtonTapped
        case fabMenuItemTapped(PinContentType)
        case overlayTapped
        case createSheetDismissed
    }

    // MARK: - Reducer
    // Note: `body` で `some ReducerOf<Self>` を使うと TCA マクロが循環参照を起こすため
    //       `reduce(into:action:)` を直接実装している。

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
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

        case .createSheetDismissed:
            state.createContentType = nil
            return .none
        }
    }
}

import ComposableArchitecture
import Foundation

@Reducer
struct AppReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var isFABExpanded: Bool = false
        var colorSchemePreference: ColorSchemePreference = {
            let raw = UserDefaults.standard.string(forKey: "colorSchemePreference") ?? "system"
            return ColorSchemePreference(rawValue: raw) ?? .system
        }()
        var reduceMotion: Bool = UserDefaults.standard.bool(forKey: "reduceMotion")
        var hapticFeedbackEnabled: Bool = {
            guard UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") != nil else { return true }
            return UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        }()
        var pinList: PinListReducer.State = .init()
        var history: HistoryReducer.State = .init()
        var search: SearchReducer.State = .init()
        @Presents var pinCreate: PinCreateReducer.State? = nil
        @Presents var settings: SettingsReducer.State? = nil
    }

    // MARK: - Tab

    enum Tab: Hashable {
        case home, history, search
    }

    // MARK: - Action

    enum Action {
        case tabSelected(Tab)
        case sceneDidBecomeActive
        case fabButtonTapped
        case fabMenuItemTapped(ContentType)
        case overlayTapped
        case pinList(PinListReducer.Action)
        case history(HistoryReducer.Action)
        case search(SearchReducer.Action)
        case create(PresentationAction<PinCreateReducer.Action>)
        case settings(PresentationAction<SettingsReducer.Action>)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.analyticsClient) var analyticsClient
            switch action {

            case let .tabSelected(tab):
                state.selectedTab = tab
                let tabName: String
                let refreshEffect: Effect<Action>
                switch tab {
                case .home:
                    tabName = "home"
                    refreshEffect = .send(.pinList(.refresh))
                case .history:
                    tabName = "history"
                    refreshEffect = .send(.history(.refresh))
                case .search:
                    tabName = "search"
                    refreshEffect = .send(.search(.refresh))
                }
                analyticsClient.logEvent(.tabSwitched(tab: tabName))
                return refreshEffect

            case .sceneDidBecomeActive:
                // Share Extension など外部からデータが追加された可能性があるため
                // 現在表示中のタブを最新データで更新する
                switch state.selectedTab {
                case .home:    return .send(.pinList(.refresh))
                case .history: return .send(.history(.refresh))
                case .search:  return .send(.search(.refresh))
                }

            case .fabButtonTapped:
                state.isFABExpanded.toggle()
                return .none

            case let .fabMenuItemTapped(type):
                state.isFABExpanded = false
                state.pinCreate = PinCreateReducer.State(contentType: type)
                analyticsClient.logEvent(.fabMenuItemTapped(contentType: type.rawValue))
                return .none

            case .overlayTapped:
                state.isFABExpanded = false
                return .none

            case let .pinList(listAction):
                if case .settingsButtonTapped = listAction {
                    state.settings = SettingsReducer.State(
                        colorScheme: state.colorSchemePreference,
                        reduceMotion: state.reduceMotion,
                        hapticFeedbackEnabled: state.hapticFeedbackEnabled
                    )
                }
                // 詳細画面の「編集」ボタン → PinCreate シートを開く
                // state.pinList.detail を直接 nil にせず .dismiss を送ることで
                // ifLet の「presented action when state absent」警告を回避する
                if case .detail(.presented(.editButtonTapped)) = listAction,
                   let pin = state.pinList.detail?.pin {
                    state.pinCreate = PinCreateReducer.State(mode: .edit(pin), contentType: pin.contentType)
                    return .send(.pinList(.detail(.dismiss)))
                }
                // 詳細画面での削除後 → 他の画面も更新
                if case .detail(.presented(.deleteResponse(.success))) = listAction {
                    return .merge(
                        .send(.history(.refresh)),
                        .send(.search(.refresh))
                    )
                }
                return .none

            case let .history(historyAction):
                // 履歴画面の詳細から「編集」ボタン → PinCreate シートを開く
                if case .detail(.presented(.editButtonTapped)) = historyAction,
                   let pin = state.history.detail?.pin {
                    state.pinCreate = PinCreateReducer.State(mode: .edit(pin), contentType: pin.contentType)
                    return .send(.history(.detail(.dismiss)))
                }
                // 詳細画面での削除後 → 他の画面も更新
                if case .detail(.presented(.deleteResponse(.success))) = historyAction {
                    return .merge(
                        .send(.pinList(.refresh)),
                        .send(.search(.refresh))
                    )
                }
                return .none

            case let .search(searchAction):
                // 検索画面の詳細から「編集」ボタン → PinCreate シートを開く
                if case .detail(.presented(.editButtonTapped)) = searchAction,
                   let pin = state.search.detail?.pin {
                    state.pinCreate = PinCreateReducer.State(mode: .edit(pin), contentType: pin.contentType)
                    return .send(.search(.detail(.dismiss)))
                }
                // 詳細画面での削除後 → 他の画面も更新
                if case .detail(.presented(.deleteResponse(.success))) = searchAction {
                    return .merge(
                        .send(.pinList(.refresh)),
                        .send(.history(.refresh))
                    )
                }
                return .none

            case .create(.presented(.saveResponse(.success))):
                // state.pinCreate を直接 nil にせず .dismiss を送ることで
                // ifLet の警告を回避する
                return .merge(
                    .send(.create(.dismiss)),
                    .send(.pinList(.refresh)),
                    .send(.history(.refresh)),
                    .send(.search(.refresh))
                )

            case .create(.presented(.cancelButtonTapped)):
                return .send(.create(.dismiss))

            case .create:
                return .none

            case let .settings(.presented(.colorSchemeChanged(preference))):
                state.colorSchemePreference = preference
                return .none

            case let .settings(.presented(.reduceMotionChanged(value))):
                state.reduceMotion = value
                return .none

            case let .settings(.presented(.hapticFeedbackChanged(value))):
                state.hapticFeedbackEnabled = value
                return .none

            case .settings(.presented(.doneButtonTapped)):
                return .send(.settings(.dismiss))

            case .settings:
                return .none
            }
        }
        .ifLet(\.$pinCreate, action: \.create) {
            PinCreateReducer()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsReducer()
        }

        Scope(state: \.pinList, action: \.pinList) {
            PinListReducer()
        }

        Scope(state: \.history, action: \.history) {
            HistoryReducer()
        }

        Scope(state: \.search, action: \.search) {
            SearchReducer()
        }
    }
}

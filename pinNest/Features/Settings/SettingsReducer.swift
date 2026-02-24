import ComposableArchitecture
import SwiftUI

// MARK: - ColorSchemePreference

enum ColorSchemePreference: String, CaseIterable, Equatable, Sendable {
    case system
    case light
    case dark

    nonisolated var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    nonisolated var label: String {
        switch self {
        case .system: return "システム"
        case .light: return "ライト"
        case .dark: return "ダーク"
        }
    }
}

// MARK: - SettingsReducer

@Reducer
struct SettingsReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var colorScheme: ColorSchemePreference
        var appVersion: String = ""
        var buildNumber: String = ""

        init(colorScheme: ColorSchemePreference = .system) {
            self.colorScheme = colorScheme
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case colorSchemeChanged(ColorSchemePreference)
        case doneButtonTapped
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                state.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
                state.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
                return .none

            case let .colorSchemeChanged(preference):
                state.colorScheme = preference
                return .run { _ in
                    UserDefaults.standard.set(preference.rawValue, forKey: "colorSchemePreference")
                }

            case .doneButtonTapped:
                return .none
            }
        }
    }
}

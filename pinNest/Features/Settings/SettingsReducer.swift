import ComposableArchitecture
import SwiftUI

// MARK: - EnvironmentValues

extension EnvironmentValues {
    @Entry var colorSchemePreference: ColorSchemePreference = .system
}

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
        var reduceMotion: Bool
        var hapticFeedbackEnabled: Bool
        var appVersion: String = ""
        var buildNumber: String = ""

        init(
            colorScheme: ColorSchemePreference = .system,
            reduceMotion: Bool = false,
            hapticFeedbackEnabled: Bool = true
        ) {
            self.colorScheme = colorScheme
            self.reduceMotion = reduceMotion
            self.hapticFeedbackEnabled = hapticFeedbackEnabled
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case colorSchemeChanged(ColorSchemePreference)
        case reduceMotionChanged(Bool)
        case hapticFeedbackChanged(Bool)
        case doneButtonTapped
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.analyticsClient) var analyticsClient
            switch action {

            case .onAppear:
                state.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
                state.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
                return .none

            case let .colorSchemeChanged(preference):
                state.colorScheme = preference
                analyticsClient.logEvent(.themeChanged(preference: preference.rawValue))
                return .run { _ in
                    UserDefaults.standard.set(preference.rawValue, forKey: "colorSchemePreference")
                }

            case let .reduceMotionChanged(value):
                state.reduceMotion = value
                analyticsClient.logEvent(.accessibilityChanged(setting: "reduce_motion", enabled: value))
                return .run { _ in
                    UserDefaults.standard.set(value, forKey: "reduceMotion")
                }

            case let .hapticFeedbackChanged(value):
                state.hapticFeedbackEnabled = value
                analyticsClient.logEvent(.accessibilityChanged(setting: "haptic_feedback", enabled: value))
                return .run { _ in
                    UserDefaults.standard.set(value, forKey: "hapticFeedbackEnabled")
                }

            case .doneButtonTapped:
                return .none
            }
        }
    }
}

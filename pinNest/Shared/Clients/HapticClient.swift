import ComposableArchitecture
import UIKit

// MARK: - Haptic Types

enum HapticImpactStyle: Sendable {
    case light, medium, heavy, soft, rigid

    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light:  .light
        case .medium: .medium
        case .heavy:  .heavy
        case .soft:   .soft
        case .rigid:  .rigid
        }
    }
}

enum HapticNotificationType: Sendable {
    case success, warning, error

    var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: .success
        case .warning: .warning
        case .error:   .error
        }
    }
}

// MARK: - Helpers

private var isHapticFeedbackEnabled: Bool {
    UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
}

// MARK: - HapticClient

struct HapticClient: Sendable {
    var impact: @Sendable (HapticImpactStyle) -> Void
    var notification: @Sendable (HapticNotificationType) -> Void
    var selection: @Sendable () -> Void
}

extension HapticClient: DependencyKey {
    static let liveValue = HapticClient(
        impact: { style in
            guard isHapticFeedbackEnabled else { return }
            UIImpactFeedbackGenerator(style: style.uiKitStyle).impactOccurred()
        },
        notification: { type in
            guard isHapticFeedbackEnabled else { return }
            UINotificationFeedbackGenerator().notificationOccurred(type.uiKitType)
        },
        selection: {
            guard isHapticFeedbackEnabled else { return }
            UISelectionFeedbackGenerator().selectionChanged()
        }
    )

    static let testValue = HapticClient(
        impact: { _ in },
        notification: { _ in },
        selection: {}
    )
}

extension DependencyValues {
    var hapticClient: HapticClient {
        get { self[HapticClient.self] }
        set { self[HapticClient.self] = newValue }
    }
}

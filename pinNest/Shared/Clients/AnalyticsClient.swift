@preconcurrency import FirebaseAnalytics
import ComposableArchitecture
import Foundation

// MARK: - AnalyticsEvent

enum AnalyticsEvent: Sendable {
    case pinCreated(contentType: String)
    case pinEdited(contentType: String)
    case pinDeleted
    case pinFavoriteToggled(isFavorite: Bool)
    case pinViewed(contentType: String)
    case urlOpened
    case searchPerformed(hasKeyword: Bool, hasTagFilter: Bool, sortOrder: String)
    case tagCreated
    case tagAssigned
    case tagRemoved
    case filterApplied(contentType: String?)
    case tabSwitched(tab: String)
    case themeChanged(preference: String)
    case fabMenuItemTapped(contentType: String)
    case metadataRefreshed
    case accessibilityChanged(setting: String, enabled: Bool)

    var eventName: String {
        switch self {
        case .pinCreated:        "pin_created"
        case .pinEdited:         "pin_edited"
        case .pinDeleted:        "pin_deleted"
        case .pinFavoriteToggled: "pin_favorite_toggled"
        case .pinViewed:         "pin_viewed"
        case .urlOpened:         "url_opened"
        case .searchPerformed:   "search_performed"
        case .tagCreated:        "tag_created"
        case .tagAssigned:       "tag_assigned"
        case .tagRemoved:        "tag_removed"
        case .filterApplied:     "filter_applied"
        case .tabSwitched:       "tab_switched"
        case .themeChanged:      "theme_changed"
        case .fabMenuItemTapped: "fab_menu_item_tapped"
        case .metadataRefreshed:     "metadata_refreshed"
        case .accessibilityChanged:  "accessibility_changed"
        }
    }

    var parameters: [String: String] {
        switch self {
        case let .pinCreated(contentType):
            ["content_type": contentType]
        case let .pinEdited(contentType):
            ["content_type": contentType]
        case .pinDeleted:
            [:]
        case let .pinFavoriteToggled(isFavorite):
            ["is_favorite": isFavorite ? "true" : "false"]
        case let .pinViewed(contentType):
            ["content_type": contentType]
        case .urlOpened:
            [:]
        case let .searchPerformed(hasKeyword, hasTagFilter, sortOrder):
            [
                "has_keyword": hasKeyword ? "true" : "false",
                "has_tag_filter": hasTagFilter ? "true" : "false",
                "sort_order": sortOrder
            ]
        case .tagCreated:
            [:]
        case .tagAssigned:
            [:]
        case .tagRemoved:
            [:]
        case let .filterApplied(contentType):
            ["content_type": contentType ?? "all"]
        case let .tabSwitched(tab):
            ["tab": tab]
        case let .themeChanged(preference):
            ["preference": preference]
        case let .fabMenuItemTapped(contentType):
            ["content_type": contentType]
        case .metadataRefreshed:
            [:]
        case let .accessibilityChanged(setting, enabled):
            ["setting": setting, "enabled": enabled ? "true" : "false"]
        }
    }
}

// MARK: - AnalyticsClient

struct AnalyticsClient: Sendable {
    var logEvent: @Sendable (AnalyticsEvent) -> Void
}

extension AnalyticsClient: DependencyKey {
    static let liveValue = AnalyticsClient(
        logEvent: { event in
            let params = event.parameters.isEmpty ? nil : event.parameters.mapValues { $0 as Any }
            Analytics.logEvent(event.eventName, parameters: params)
        }
    )

    static let testValue = AnalyticsClient(
        logEvent: { _ in }
    )
}

extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

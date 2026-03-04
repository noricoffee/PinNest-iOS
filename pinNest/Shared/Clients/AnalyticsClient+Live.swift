@preconcurrency import FirebaseAnalytics
import ComposableArchitecture

extension AnalyticsClient: DependencyKey {
    static let liveValue = AnalyticsClient(
        logEvent: { event in
            let params = event.parameters.isEmpty ? nil : event.parameters.mapValues { $0 as Any }
            Analytics.logEvent(event.eventName, parameters: params)
        }
    )
}

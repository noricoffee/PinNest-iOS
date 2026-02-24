@preconcurrency import FirebaseCrashlytics
import ComposableArchitecture
import Foundation

// MARK: - CrashlyticsClient

struct CrashlyticsClient: Sendable {
    /// エラーを non-fatal として記録する。context には "PinClient.create" などの操作名を渡す
    var recordError: @Sendable (Error, String) -> Void
}

extension CrashlyticsClient: DependencyKey {
    static let liveValue = CrashlyticsClient(
        recordError: { error, context in
            let instance = Crashlytics.crashlytics()
            instance.log("[\(context)] \(error.localizedDescription)")
            instance.record(error: error)
        }
    )

    static let testValue = CrashlyticsClient(
        recordError: { _, _ in }
    )
}

extension DependencyValues {
    var crashlyticsClient: CrashlyticsClient {
        get { self[CrashlyticsClient.self] }
        set { self[CrashlyticsClient.self] = newValue }
    }
}

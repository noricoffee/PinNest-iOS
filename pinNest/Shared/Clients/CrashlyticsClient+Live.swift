@preconcurrency import FirebaseCrashlytics
import ComposableArchitecture

extension CrashlyticsClient: DependencyKey {
    static let liveValue = CrashlyticsClient(
        recordError: { error, context in
            let instance = Crashlytics.crashlytics()
            instance.log("[\(context)] \(error.localizedDescription)")
            instance.record(error: error)
        }
    )
}

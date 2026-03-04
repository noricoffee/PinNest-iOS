import ComposableArchitecture
import Foundation

// MARK: - CrashlyticsClient

struct CrashlyticsClient: Sendable {
    /// エラーを non-fatal として記録する。context には "PinClient.create" などの操作名を渡す
    var recordError: @Sendable (Error, String) -> Void
}

extension CrashlyticsClient: TestDependencyKey {
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

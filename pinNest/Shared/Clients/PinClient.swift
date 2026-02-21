import Dependencies
import Foundation

struct PinClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Pin]
    var create: @Sendable (Pin) async throws -> Void
    var update: @Sendable (Pin) async throws -> Void
    var delete: @Sendable (UUID) async throws -> Void
}

extension PinClient: DependencyKey {
    // Phase 2 で SwiftData を使った実装に差し替える
    static let liveValue = PinClient(
        fetchAll: { [] },
        create: { _ in },
        update: { _ in },
        delete: { _ in }
    )

    static let testValue = PinClient(
        fetchAll: unimplemented("\(Self.self).fetchAll", placeholder: []),
        create: unimplemented("\(Self.self).create"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete")
    )
}

extension DependencyValues {
    var pinClient: PinClient {
        get { self[PinClient.self] }
        set { self[PinClient.self] = newValue }
    }
}

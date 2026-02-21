import Dependencies
import Foundation
import SwiftData

struct PinClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Pin]
    var create: @Sendable (Pin) async throws -> Void
    var update: @Sendable (Pin) async throws -> Void
    var delete: @Sendable (UUID) async throws -> Void
}

// MARK: - Live Implementation

extension PinClient: DependencyKey {
    static let liveValue: PinClient = {
        let container: ModelContainer
        do {
            let schema = Schema([Pin.self, PinCollection.self, Tag.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let store = PinDataStore(modelContainer: container)

        return PinClient(
            fetchAll: {
                try await store.fetchAll()
            },
            create: { pin in
                try await store.create(pin)
            },
            update: { pin in
                try await store.update(
                    id: pin.id,
                    title: pin.title,
                    memo: pin.memo,
                    isFavorite: pin.isFavorite,
                    urlString: pin.urlString,
                    filePath: pin.filePath,
                    bodyText: pin.bodyText
                )
            },
            delete: { id in
                try await store.delete(id: id)
            }
        )
    }()

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

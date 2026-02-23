import Dependencies
import Foundation
import SwiftData

// MARK: - NewPin (value type for create)

/// @Model の Pin をアクター境界を越えて渡せないため、
/// create 時は value type で必要なフィールドを受け渡し、
/// Pin の生成は @ModelActor 内で行う。
struct NewPin: Sendable {
    var id: UUID = UUID()
    var contentType: ContentType
    var title: String
    var memo: String = ""
    var urlString: String? = nil
    var filePath: String? = nil
    var bodyText: String? = nil
}

// MARK: - PinClient

struct PinClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Pin]
    var create: @Sendable (NewPin) async throws -> Void
    var update: @Sendable (UUID, String, String, Bool, String?, String?, String?) async throws -> Void
    var delete: @Sendable (UUID) async throws -> Void
}

// MARK: - Live Implementation

extension PinClient: DependencyKey {
    static let liveValue: PinClient = {
        let container: ModelContainer
        do {
            let schema = Schema([Pin.self, Tag.self])
            // App Group コンテナが利用可能な場合はそちらに保存（Share Extension と共有）
            let config: ModelConfiguration
            if let storeURL = AppGroupContainer.storeURL {
                config = ModelConfiguration(schema: schema, url: storeURL)
            } else {
                config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            }
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let store = PinDataStore(modelContainer: container)

        return PinClient(
            fetchAll: {
                try await store.fetchAll()
            },
            create: { newPin in
                try await store.create(newPin)
            },
            update: { id, title, memo, isFavorite, urlString, filePath, bodyText in
                try await store.update(
                    id: id,
                    title: title,
                    memo: memo,
                    isFavorite: isFavorite,
                    urlString: urlString,
                    filePath: filePath,
                    bodyText: bodyText
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

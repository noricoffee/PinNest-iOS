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

// MARK: - TagItem (value type for tag)

/// @Model の Tag をアクター境界を越えて渡せないため、
/// value type で必要なフィールドのみを保持する。
struct TagItem: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
}

// MARK: - PinSortOrder

enum PinSortOrder: String, CaseIterable, Equatable, Sendable {
    case newestFirst = "新しい順"
    case oldestFirst = "古い順"
}

// MARK: - PinClient

struct PinClient: Sendable {
    // Existing
    var fetchAll: @Sendable () async throws -> [Pin]
    var create: @Sendable (NewPin) async throws -> Void
    var update: @Sendable (UUID, String, String, Bool, String?, String?, String?) async throws -> Void
    var delete: @Sendable (UUID) async throws -> Void

    // Search
    var search: @Sendable (String, Set<UUID>, PinSortOrder) async throws -> [Pin]

    // Tags
    var fetchAllTags: @Sendable () async throws -> [TagItem]
    var createTag: @Sendable (String) async throws -> TagItem
    var deleteTag: @Sendable (UUID) async throws -> Void
    var addTagToPin: @Sendable (UUID, UUID) async throws -> Void       // tagId, pinId
    var removeTagFromPin: @Sendable (UUID, UUID) async throws -> Void  // tagId, pinId
    var fetchTagsForPin: @Sendable (UUID) async throws -> [TagItem]
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
            },
            search: { keyword, tagIds, sortOrder in
                try await store.search(keyword: keyword, tagIds: tagIds, sortOrder: sortOrder)
            },
            fetchAllTags: {
                try await store.fetchAllTags()
            },
            createTag: { name in
                try await store.createTag(name: name)
            },
            deleteTag: { id in
                try await store.deleteTag(id: id)
            },
            addTagToPin: { tagId, pinId in
                try await store.addTag(tagId: tagId, toPinId: pinId)
            },
            removeTagFromPin: { tagId, pinId in
                try await store.removeTag(tagId: tagId, fromPinId: pinId)
            },
            fetchTagsForPin: { pinId in
                try await store.fetchTagsForPin(pinId: pinId)
            }
        )
    }()

    static let testValue = PinClient(
        fetchAll: unimplemented("\(Self.self).fetchAll", placeholder: []),
        create: unimplemented("\(Self.self).create"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete"),
        search: unimplemented("\(Self.self).search", placeholder: []),
        fetchAllTags: unimplemented("\(Self.self).fetchAllTags", placeholder: []),
        createTag: unimplemented("\(Self.self).createTag", placeholder: TagItem(id: UUID(), name: "")),
        deleteTag: unimplemented("\(Self.self).deleteTag"),
        addTagToPin: unimplemented("\(Self.self).addTagToPin"),
        removeTagFromPin: unimplemented("\(Self.self).removeTagFromPin"),
        fetchTagsForPin: unimplemented("\(Self.self).fetchTagsForPin", placeholder: [])
    )
}

extension DependencyValues {
    var pinClient: PinClient {
        get { self[PinClient.self] }
        set { self[PinClient.self] = newValue }
    }
}

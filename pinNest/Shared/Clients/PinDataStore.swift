import Foundation
import SwiftData

/// SwiftData を使った CRUD 操作を @ModelActor actor として実装する。
/// PinClient.liveValue から保持・呼び出しを行う。
@ModelActor
actor PinDataStore {

    // MARK: - Fetch

    func fetchAll() throws -> [Pin] {
        let descriptor = FetchDescriptor<Pin>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Create

    /// Pin の生成を @ModelActor 内で行うことで、
    /// actor 境界を越えた @Model 渡しによるクラッシュを防ぐ。
    func create(_ newPin: NewPin) throws {
        let pin = Pin(
            id: newPin.id,
            contentType: newPin.contentType,
            title: newPin.title,
            memo: newPin.memo,
            urlString: newPin.urlString,
            filePath: newPin.filePath,
            bodyText: newPin.bodyText
        )
        modelContext.insert(pin)
        try modelContext.save()
    }

    // MARK: - Update

    /// 既存ピンのメタデータを更新して保存する。
    /// `pin` は fetchAll で取得した同一 ModelContext に属するオブジェクトを渡すこと。
    func update(
        id: UUID,
        title: String,
        memo: String,
        isFavorite: Bool,
        urlString: String?,
        filePath: String?,
        bodyText: String?
    ) throws {
        let predicate = #Predicate<Pin> { $0.id == id }
        let descriptor = FetchDescriptor<Pin>(predicate: predicate)
        guard let pin = try modelContext.fetch(descriptor).first else { return }

        pin.title = title
        pin.memo = memo
        pin.isFavorite = isFavorite
        pin.urlString = urlString
        pin.filePath = filePath
        pin.bodyText = bodyText

        try modelContext.save()
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        let predicate = #Predicate<Pin> { $0.id == id }
        let descriptor = FetchDescriptor<Pin>(predicate: predicate)
        guard let pin = try modelContext.fetch(descriptor).first else { return }

        modelContext.delete(pin)
        try modelContext.save()
    }

    // MARK: - Search

    /// キーワード・タグ・ソート順でピンを絞り込む。
    /// SwiftData #Predicate のオプショナル制限を回避するため、全件取得後にメモリフィルターする。
    func search(keyword: String, tagIds: Set<UUID>, sortOrder: PinSortOrder) throws -> [Pin] {
        let order: Foundation.SortOrder = sortOrder == .newestFirst ? .reverse : .forward
        let descriptor = FetchDescriptor<Pin>(
            sortBy: [SortDescriptor(\.createdAt, order: order)]
        )
        var pins = try modelContext.fetch(descriptor)

        if !keyword.isEmpty {
            pins = pins.filter { pin in
                pin.title.localizedStandardContains(keyword)
                || pin.memo.localizedStandardContains(keyword)
                || (pin.bodyText?.localizedStandardContains(keyword) ?? false)
                || (pin.urlString?.localizedStandardContains(keyword) ?? false)
            }
        }

        if !tagIds.isEmpty {
            let favoriteSelected = tagIds.contains(TagItem.favoriteID)
            let realTagIds = tagIds.subtracting([TagItem.favoriteID])
            pins = pins.filter { pin in
                let matchesFavorite = favoriteSelected && pin.isFavorite
                let matchesTag = !realTagIds.isEmpty && pin.tags.contains { realTagIds.contains($0.id) }
                return matchesFavorite || matchesTag
            }
        }

        return pins
    }

    // MARK: - Tag CRUD

    func fetchAllTags() throws -> [TagItem] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor).map { TagItem(id: $0.id, name: $0.name) }
    }

    func createTag(name: String) throws -> TagItem {
        let tag = Tag(name: name)
        modelContext.insert(tag)
        try modelContext.save()
        return TagItem(id: tag.id, name: tag.name)
    }

    func deleteTag(id: UUID) throws {
        let predicate = #Predicate<Tag> { $0.id == id }
        let descriptor = FetchDescriptor<Tag>(predicate: predicate)
        guard let tag = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(tag)
        try modelContext.save()
    }

    // MARK: - Tag–Pin Relationship

    func addTag(tagId: UUID, toPinId: UUID) throws {
        let tagPredicate = #Predicate<Tag> { $0.id == tagId }
        let pinPredicate = #Predicate<Pin> { $0.id == toPinId }
        guard let tag = try modelContext.fetch(FetchDescriptor<Tag>(predicate: tagPredicate)).first,
              let pin = try modelContext.fetch(FetchDescriptor<Pin>(predicate: pinPredicate)).first
        else { return }

        if !pin.tags.contains(where: { $0.id == tagId }) {
            pin.tags.append(tag)
        }
        try modelContext.save()
    }

    func removeTag(tagId: UUID, fromPinId: UUID) throws {
        let pinPredicate = #Predicate<Pin> { $0.id == fromPinId }
        guard let pin = try modelContext.fetch(FetchDescriptor<Pin>(predicate: pinPredicate)).first else { return }
        pin.tags.removeAll { $0.id == tagId }
        try modelContext.save()
    }

    func fetchTagsForPin(pinId: UUID) throws -> [TagItem] {
        let predicate = #Predicate<Pin> { $0.id == pinId }
        let descriptor = FetchDescriptor<Pin>(predicate: predicate)
        guard let pin = try modelContext.fetch(descriptor).first else { return [] }
        return pin.tags.map { TagItem(id: $0.id, name: $0.name) }
    }
}

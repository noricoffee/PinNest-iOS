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
}

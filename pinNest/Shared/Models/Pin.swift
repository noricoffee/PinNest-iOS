import Foundation
import SwiftData

@Model
final class Pin {
    #Unique<Pin>([\.id])

    var id: UUID
    var contentType: ContentType
    var title: String
    var memo: String
    var createdAt: Date
    var isFavorite: Bool

    // URL ペイロード
    var urlString: String?

    // 画像 / 動画 / PDF のファイルパス（アプリコンテナ内の相対パス）
    var filePath: String?

    // テキストペイロード
    var bodyText: String?

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify, inverse: \Tag.pins)
    var tags: [Tag] = []

    @Relationship(deleteRule: .nullify, inverse: \PinCollection.pins)
    var collection: PinCollection?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        contentType: ContentType,
        title: String,
        memo: String = "",
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        urlString: String? = nil,
        filePath: String? = nil,
        bodyText: String? = nil
    ) {
        self.id = id
        self.contentType = contentType
        self.title = title
        self.memo = memo
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.urlString = urlString
        self.filePath = filePath
        self.bodyText = bodyText
    }
}

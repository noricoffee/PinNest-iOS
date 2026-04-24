import Foundation
import SwiftData

@Model
final class Pin: @unchecked Sendable {
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

    // MARK: - Computed

    /// filePath を絶対 URL に解決して返す（相対パス・レガシー絶対パス両対応）
    /// ビルド・再インストール時にサンドボックスパスが変わっても正しく解決できる
    var absoluteFilePath: URL? {
        guard let path = filePath else { return nil }
        return URL(fileURLWithPath: ThumbnailCache.resolveAbsolutePath(path))
    }

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify, inverse: \Tag.pins)
    var tags: [Tag] = []

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

import Foundation

// Phase 2 で SwiftData @Model に移行する
struct Pin: Identifiable, Equatable, Sendable {
    var id: UUID
    var contentType: ContentType
    var title: String
    var memo: String
    var createdAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        contentType: ContentType,
        title: String,
        memo: String = "",
        createdAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.contentType = contentType
        self.title = title
        self.memo = memo
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
}

// Phase 2 で ContentType のペイロード設計を行う
enum ContentType: String, Equatable, Sendable, CaseIterable {
    case url
    case image
    case video
    case pdf
    case text
}

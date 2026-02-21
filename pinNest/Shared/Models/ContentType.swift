import Foundation

/// ピンのコンテンツ種別
enum ContentType: String, Codable, Hashable, Sendable, CaseIterable {
    case url
    case image
    case video
    case pdf
    case text
}

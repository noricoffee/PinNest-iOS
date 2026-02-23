import Foundation
import SwiftUI

/// ピンのコンテンツ種別
/// SwiftUI の import は ContentType+Display.swift に切り出して @MainActor 隔離を防ぐ
enum ContentType: String, Codable, Hashable, Sendable, CaseIterable {
    case url
    case image
    case video
    case pdf
    case text

    // MARK: - Display (nonisolated で @MainActor 隔離を回避)

    nonisolated var iconName: String {
        switch self {
        case .url:   "globe"
        case .image: "photo.fill"
        case .video: "play.rectangle.fill"
        case .pdf:   "doc.richtext.fill"
        case .text:  "doc.text.fill"
        }
    }

    nonisolated var label: String {
        switch self {
        case .url:   "URL"
        case .image: "画像"
        case .video: "動画"
        case .pdf:   "PDF"
        case .text:  "テキスト"
        }
    }

    /// マソンリーグリッド・カードのデフォルトアスペクト比
    nonisolated var defaultAspectRatio: Double {
        switch self {
        case .url:   16.0 / 9.0
        case .image: 4.0 / 3.0
        case .video: 16.0 / 9.0
        case .pdf:   1.0
        case .text:  1.0
        }
    }

    /// カードサムネイルのデフォルト表示色
    nonisolated var displayColor: Color {
        switch self {
        case .url:   .blue.opacity(0.55)
        case .image: .orange.opacity(0.55)
        case .video: .teal.opacity(0.65)
        case .pdf:   .red.opacity(0.5)
        case .text:  .secondary.opacity(0.3)
        }
    }
}

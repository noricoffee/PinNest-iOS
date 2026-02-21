import SwiftUI

// MARK: - PinContentType

enum PinContentType: CaseIterable, Identifiable {
    var id: Self { self }
    case url, image, video, pdf, text

    var iconName: String {
        switch self {
        case .url:   "globe"
        case .image: "photo.fill"
        case .video: "play.rectangle.fill"
        case .pdf:   "doc.richtext.fill"
        case .text:  "doc.text.fill"
        }
    }

    var label: String {
        switch self {
        case .url:   "URL"
        case .image: "画像"
        case .video: "動画"
        case .pdf:   "PDF"
        case .text:  "テキスト"
        }
    }
}

// MARK: - PinPreviewItem

/// UI プロトタイプ用のプレビューデータモデル
/// SwiftData モデル実装後に置き換える
struct PinPreviewItem: Identifiable {
    let id = UUID()
    let contentType: PinContentType
    let title: String
    let subtitle: String?
    let thumbnailColor: Color
    let thumbnailAspectRatio: CGFloat
    let previewText: String?
    let addedAt: Date

    init(
        contentType: PinContentType,
        title: String,
        subtitle: String? = nil,
        thumbnailColor: Color = .gray.opacity(0.4),
        thumbnailAspectRatio: CGFloat = 16 / 9,
        previewText: String? = nil,
        addedAt: Date = Date()
    ) {
        self.contentType = contentType
        self.title = title
        self.subtitle = subtitle
        self.thumbnailColor = thumbnailColor
        self.thumbnailAspectRatio = thumbnailAspectRatio
        self.previewText = previewText
        self.addedAt = addedAt
    }
}

// MARK: - Sample Data

extension PinPreviewItem {
    static let samples: [PinPreviewItem] = {
        let cal = Calendar.current
        let now = Date()
        func ago(days: Int = 0, hours: Int = 0) -> Date {
            cal.date(byAdding: DateComponents(day: -days, hour: -hours), to: now) ?? now
        }
        return [
            PinPreviewItem(
                contentType: .image,
                title: "夕暮れの富士山",
                thumbnailColor: .orange.opacity(0.65),
                thumbnailAspectRatio: 4 / 3,
                addedAt: ago(hours: 1)
            ),
            PinPreviewItem(
                contentType: .url,
                title: "SwiftUI でマソンリーレイアウトを実装する",
                subtitle: "developer.apple.com",
                thumbnailColor: .blue.opacity(0.55),
                thumbnailAspectRatio: 16 / 9,
                addedAt: ago(hours: 3)
            ),
            PinPreviewItem(
                contentType: .text,
                title: "買い物メモ",
                previewText: "・牛乳\n・卵\n・食パン\n・ジュース\n・チーズ",
                addedAt: ago(days: 1)
            ),
            PinPreviewItem(
                contentType: .url,
                title: "The Composable Architecture",
                subtitle: "github.com",
                thumbnailColor: .purple.opacity(0.5),
                thumbnailAspectRatio: 16 / 9,
                addedAt: ago(days: 2)
            ),
            PinPreviewItem(
                contentType: .image,
                title: "カフェのラテアート",
                thumbnailColor: .brown.opacity(0.55),
                thumbnailAspectRatio: 1,
                addedAt: ago(days: 3)
            ),
            PinPreviewItem(
                contentType: .pdf,
                title: "プロジェクト設計書 v2.0",
                addedAt: ago(days: 5)
            ),
            PinPreviewItem(
                contentType: .video,
                title: "WWDC 2025 Keynote Highlights",
                thumbnailColor: .teal.opacity(0.65),
                thumbnailAspectRatio: 16 / 9,
                addedAt: ago(days: 7)
            ),
            PinPreviewItem(
                contentType: .url,
                title: "iOS 26 の新機能まとめ",
                subtitle: "zenn.dev",
                thumbnailColor: .green.opacity(0.45),
                thumbnailAspectRatio: 16 / 9,
                addedAt: ago(days: 10)
            ),
            PinPreviewItem(
                contentType: .text,
                title: "アイデアメモ",
                previewText: "pinNest のアイコンアイデア\n・巣に刺さったピン\n・鳥の巣モチーフ",
                addedAt: ago(days: 14)
            ),
            PinPreviewItem(
                contentType: .image,
                title: "桜並木",
                thumbnailColor: .pink.opacity(0.5),
                thumbnailAspectRatio: 3 / 2,
                addedAt: ago(days: 21)
            ),
        ]
    }()
}

import Dependencies
import Foundation
import SwiftData
import UIKit

// MARK: - DemoData

/// App Store スクリーンショット用のデモデータ。
/// Launch Argument に `-demoMode` を追加すると有効になる。
enum DemoData {

    /// デモモードかどうか
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-demoMode")
    }

    // MARK: - Fixed UUIDs (サムネイルキャッシュとの紐付けに使用)

    private static let ids: [UUID] = [
        UUID(uuidString: "D0000000-0001-0000-0000-000000000001")!,
        UUID(uuidString: "D0000000-0002-0000-0000-000000000002")!,
        UUID(uuidString: "D0000000-0003-0000-0000-000000000003")!,
        UUID(uuidString: "D0000000-0004-0000-0000-000000000004")!,
        UUID(uuidString: "D0000000-0005-0000-0000-000000000005")!,
        UUID(uuidString: "D0000000-0006-0000-0000-000000000006")!,
        UUID(uuidString: "D0000000-0007-0000-0000-000000000007")!,
        UUID(uuidString: "D0000000-0008-0000-0000-000000000008")!,
        UUID(uuidString: "D0000000-0009-0000-0000-000000000009")!,
        UUID(uuidString: "D0000000-000A-0000-0000-00000000000A")!,
        UUID(uuidString: "D0000000-000B-0000-0000-00000000000B")!,
    ]

    // MARK: - Demo Pins Definition

    private struct DemoEntry {
        let contentType: ContentType
        let title: String
        let memo: String
        let isFavorite: Bool
        let urlString: String?
        let bodyText: String?
        /// Asset Catalog 内の画像名（サムネイル用）
        let assetName: String?
        /// createdAt の日数オフセット（今日から何日前か）
        let daysAgo: Int
    }

    private static let entries: [DemoEntry] = [
        DemoEntry(
            contentType: .url,
            title: "SwiftUI の新機能まとめ — WWDC26",
            memo: "後で読む",
            isFavorite: true,
            urlString: "https://developer.apple.com/swiftui/",
            bodyText: nil,
            assetName: "demo_1",
            daysAgo: 0
        ),
        DemoEntry(
            contentType: .image,
            title: "旅行で撮った夕焼け",
            memo: "鎌倉の海岸にて",
            isFavorite: true,
            urlString: nil,
            bodyText: nil,
            assetName: "demo_3",
            daysAgo: 1
        ),
        DemoEntry(
            contentType: .url,
            title: "デザインシステムの構築ガイド",
            memo: "",
            isFavorite: false,
            urlString: "https://design.example.com/guide",
            bodyText: nil,
            assetName: "demo_2",
            daysAgo: 1
        ),
        DemoEntry(
            contentType: .text,
            title: "買い物メモ",
            memo: "",
            isFavorite: false,
            urlString: nil,
            bodyText: "牛乳、卵、食パン、バター、ほうれん草、鶏むね肉、玉ねぎ、にんじん、トマト缶、パスタ",
            assetName: nil,
            daysAgo: 2
        ),
        DemoEntry(
            contentType: .video,
            title: "プレゼン録画 — Q3レビュー",
            memo: "チームミーティングで共有",
            isFavorite: false,
            urlString: nil,
            bodyText: nil,
            assetName: "demo_5",
            daysAgo: 3
        ),
        DemoEntry(
            contentType: .image,
            title: "新緑の公園",
            memo: "",
            isFavorite: false,
            urlString: nil,
            bodyText: nil,
            assetName: "demo_4",
            daysAgo: 3
        ),
        DemoEntry(
            contentType: .url,
            title: "GitHub Copilot の活用テクニック",
            memo: "開発効率化のヒント",
            isFavorite: true,
            urlString: "https://github.blog/copilot-tips",
            bodyText: nil,
            assetName: "demo_7",
            daysAgo: 4
        ),
        DemoEntry(
            contentType: .pdf,
            title: "プロジェクト企画書_v2.pdf",
            memo: "最終版",
            isFavorite: false,
            urlString: nil,
            bodyText: nil,
            assetName: "demo_6",
            daysAgo: 5
        ),
        DemoEntry(
            contentType: .text,
            title: "アプリのアイデアメモ",
            memo: "",
            isFavorite: true,
            urlString: nil,
            bodyText: "習慣トラッカー × SNS 要素。友達と目標を共有してモチベーション維持。ウィジェット対応で毎日リマインド。",
            assetName: nil,
            daysAgo: 5
        ),
        DemoEntry(
            contentType: .url,
            title: "Swift Concurrency ベストプラクティス",
            memo: "",
            isFavorite: false,
            urlString: "https://swift.org/blog/concurrency/",
            bodyText: nil,
            assetName: "demo_1",
            daysAgo: 7
        ),
        DemoEntry(
            contentType: .text,
            title: "読書リスト 2026",
            memo: "今年中に読みたい本",
            isFavorite: false,
            urlString: nil,
            bodyText: "1. リファクタリング 第2版\n2. Clean Architecture\n3. システム設計の面接試験\n4. プログラミング言語の基礎理論\n5. ドメイン駆動設計入門",
            assetName: nil,
            daysAgo: 10
        ),
    ]

    // MARK: - Setup

    /// デモ用サムネイル画像を ThumbnailCache に書き出す
    static func setupThumbnails() {
        for (index, entry) in entries.enumerated() {
            guard let assetName = entry.assetName,
                  let uiImage = UIImage(named: assetName),
                  let jpegData = uiImage.jpegData(compressionQuality: 0.85) else { continue }
            _ = try? ThumbnailCache.save(data: jpegData, for: ids[index])
        }
    }

    private static func thumbnailRelativePath(for pinID: UUID) -> String {
        "Library/Caches/thumbnails/\(pinID.uuidString).jpg"
    }

    // MARK: - Demo PinClient

    /// デモ用の PinClient（in-memory ModelContainer + PinDataStore で @Model を正しく管理）
    static var demoClient: PinClient {
        let container: ModelContainer
        do {
            let schema = Schema([Pin.self, Tag.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create demo ModelContainer: \(error)")
        }

        let store = PinDataStore(modelContainer: container)
        let now = Date()

        // デモデータを同期的に insert（in-memory なので高速）
        let context = ModelContext(container)
        for (index, entry) in entries.enumerated() {
            let pin = Pin(
                id: ids[index],
                contentType: entry.contentType,
                title: entry.title,
                memo: entry.memo,
                createdAt: Calendar.current.date(byAdding: .day, value: -entry.daysAgo, to: now) ?? now,
                isFavorite: entry.isFavorite,
                urlString: entry.urlString,
                filePath: entry.assetName != nil ? thumbnailRelativePath(for: ids[index]) : nil,
                bodyText: entry.bodyText
            )
            context.insert(pin)
        }

        // デモ用タグを作成して一部のピンに紐付け
        let tagWork = Tag(name: "仕事")
        let tagPrivate = Tag(name: "プライベート")
        let tagReadLater = Tag(name: "あとで読む")
        context.insert(tagWork)
        context.insert(tagPrivate)
        context.insert(tagReadLater)

        try? context.save()

        return PinClient(
            fetchAll: {
                try await store.fetchAll()
            },
            create: { newPin in
                try await store.create(newPin)
            },
            update: { id, title, memo, isFavorite, urlString, filePath, bodyText in
                try await store.update(
                    id: id, title: title, memo: memo,
                    isFavorite: isFavorite, urlString: urlString,
                    filePath: filePath, bodyText: bodyText
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
    }
}

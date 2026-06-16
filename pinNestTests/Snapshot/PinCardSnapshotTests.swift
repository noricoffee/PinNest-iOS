import SnapshotTesting
import SwiftUI
import Testing

/// PinCardView のヴィジュアルリグレッションテスト。
/// 各コンテンツタイプ × ライト/ダークの見た目を固定する。
@MainActor
@Suite("PinCard Snapshot")
struct PinCardSnapshotTests {
    @Test func urlCard() {
        let pin = makeSnapshotPin(
            contentType: .url,
            title: "Apple（日本）",
            urlString: "https://www.apple.com/jp/"
        )
        assertSnapshotInBothColorSchemes(
            of: PinCardView(pin: pin),
            width: SnapshotConfig.cardWidth,
            named: "url"
        )
    }

    @Test func imageCard() {
        let pin = makeSnapshotPin(contentType: .image, title: "風景写真")
        assertSnapshotInBothColorSchemes(
            of: PinCardView(pin: pin),
            width: SnapshotConfig.cardWidth,
            named: "image"
        )
    }

    @Test func videoCard() {
        let pin = makeSnapshotPin(contentType: .video, title: "デモ動画")
        assertSnapshotInBothColorSchemes(
            of: PinCardView(pin: pin),
            width: SnapshotConfig.cardWidth,
            named: "video"
        )
    }

    @Test func pdfCard() {
        let pin = makeSnapshotPin(contentType: .pdf, title: "仕様書.pdf")
        assertSnapshotInBothColorSchemes(
            of: PinCardView(pin: pin),
            width: SnapshotConfig.cardWidth,
            named: "pdf"
        )
    }

    @Test func textCard() {
        let pin = makeSnapshotPin(
            contentType: .text,
            title: "メモ",
            bodyText: "あとで読み返したいメモの本文。複数行にわたる長めのテキストでも 5 行で省略される挙動を固定する。"
        )
        assertSnapshotInBothColorSchemes(
            of: PinCardView(pin: pin),
            width: SnapshotConfig.cardWidth,
            named: "text"
        )
    }

    @Test func favoriteCard() {
        let pin = makeSnapshotPin(
            contentType: .url,
            title: "お気に入りのページ",
            urlString: "https://developer.apple.com/",
            isFavorite: true
        )
        assertSnapshotInBothColorSchemes(
            of: PinCardView(pin: pin),
            width: SnapshotConfig.cardWidth,
            named: "favorite"
        )
    }
}

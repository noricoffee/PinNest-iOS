import SnapshotTesting
import SwiftUI
import Testing
import UIKit

// MARK: - スナップショット共通設定

/// ヴィジュアルリグレッションテストの共通パラメータ。
/// 決定論性を保つため、機種・OS をシミュレータで固定して記録・検証する想定。
/// （固定ターゲット: iPhone 16 / iOS 26.1）
@MainActor
enum SnapshotConfig {
    /// ピクセル一致率。1.0 = 完全一致。
    static let precision: Float = 1.0
    /// 知覚的一致率。アンチエイリアスやマテリアル(blur)の微差を許容する。
    static let perceptualPrecision: Float = 0.98
    /// カードコンポーネントの基準幅（ホーム 2 カラムグリッド相当）。
    static let cardWidth: CGFloat = 180
}

// MARK: - スナップショットヘルパー

/// View をライト/ダーク両モードでスナップショットする。
///
/// 幅を固定し、高さは top-down 提案（幅=固定 / 高さ=∞）で実測してから `.fixed` で撮る。
/// `Color + aspectRatio(.fit)` のように固有の高さを持たないサムネイルは
/// `.sizeThatFits`（圧縮フィッティング）だと高さ 0 に潰れるため、この方式で
/// 実機グリッド（親が幅を与え高さが導出される）と同じレイアウトを再現する。
/// - Parameters:
///   - view: 対象 View
///   - width: 固定幅
///   - name: スナップショット名。末尾に `.light` / `.dark` が付与される
@MainActor
func assertSnapshotInBothColorSchemes(
    of view: some View,
    width: CGFloat,
    named name: String,
    record: SnapshotTestingConfiguration.Record? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let sized = view.frame(width: width)

    for style: UIUserInterfaceStyle in [.light, .dark] {
        let traits = UITraitCollection(userInterfaceStyle: style)

        // 幅固定・高さ無限で実測し、コンテンツの自然な高さを得る
        let host = UIHostingController(
            rootView: sized.environment(\.colorScheme, style == .dark ? .dark : .light)
        )
        host.overrideUserInterfaceStyle = style
        let fitted = host.sizeThatFits(
            in: CGSize(width: width, height: .greatestFiniteMagnitude)
        )

        let suffix = style == .light ? "light" : "dark"
        assertSnapshot(
            of: sized,
            as: .image(
                precision: SnapshotConfig.precision,
                perceptualPrecision: SnapshotConfig.perceptualPrecision,
                layout: .fixed(width: width, height: fitted.height.rounded(.up)),
                traits: traits
            ),
            named: "\(name).\(suffix)",
            record: record,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

// MARK: - テスト用モデルファクトリ

/// 決定論的な Pin を生成する。
/// id / createdAt を固定し、サムネイルはプレースホルダー分岐になるよう
/// filePath を nil にしてディスク依存を排除する。
@MainActor
func makeSnapshotPin(
    contentType: ContentType,
    title: String,
    urlString: String? = nil,
    bodyText: String? = nil,
    isFavorite: Bool = false
) -> Pin {
    Pin(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        contentType: contentType,
        title: title,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        isFavorite: isFavorite,
        urlString: urlString,
        filePath: nil,
        bodyText: bodyText
    )
}

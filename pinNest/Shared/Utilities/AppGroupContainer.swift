import Foundation

/// App Group コンテナへのアクセスを管理するユーティリティ。
/// ホストアプリと Share Extension で SwiftData ストア・サムネイル・ファイルを共有するために使用する。
enum AppGroupContainer {

    /// App Group 識別子（Xcode の Signing & Capabilities で設定したものと一致させること）
    static let groupID = "group.com.noricoffee.pinNest"

    /// App Group コンテナのルート URL
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// SwiftData ストアの URL（App Group コンテナ内）
    static var storeURL: URL? {
        containerURL?.appendingPathComponent("pinNest.sqlite")
    }

    /// サムネイル保存先ディレクトリ（App Group コンテナ内）
    /// URL ピンの og:image / favicon キャッシュ用
    static var thumbnailsURL: URL? {
        makeDirectory(name: "thumbnails")
    }

    /// ファイル保存先ディレクトリ（App Group コンテナ内）
    /// 画像・動画・PDF ピンのデータ保存用
    static var filesURL: URL? {
        makeDirectory(name: "files")
    }

    // MARK: - Private

    private static func makeDirectory(name: String) -> URL? {
        guard let base = containerURL else { return nil }
        let dir = base.appendingPathComponent(name, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

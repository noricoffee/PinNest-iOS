import Foundation
import UIKit

/// URL ピンのサムネイル画像をアプリのキャッシュディレクトリに保存・読み込みするユーティリティ
enum ThumbnailCache {

    // MARK: - Save

    /// 画像データを JPEG として保存し、ホームディレクトリからの相対パスを返す
    /// - Parameters:
    ///   - data: 画像データ（JPEG / PNG 等）
    ///   - pinID: 保存先ファイル名に使う Pin の ID
    /// - Returns: NSHomeDirectory() からの相対パス（例: "Library/Caches/thumbnails/xxx.jpg"）
    static func save(data: Data, for pinID: UUID) throws -> String {
        let dir = try cacheDirectory()
        let fileURL = dir.appendingPathComponent("\(pinID.uuidString).jpg")

        if let uiImage = UIImage(data: data),
           let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
            try jpegData.write(to: fileURL, options: .atomic)
        } else {
            try data.write(to: fileURL, options: .atomic)
        }

        return toRelativePath(fileURL.path)
    }

    // MARK: - Load

    /// ファイルパスから UIImage をロードする（相対パス・絶対パス両対応）
    static func loadImage(path: String) -> UIImage? {
        UIImage(contentsOfFile: resolveAbsolutePath(path))
    }

    // MARK: - Remove

    /// キャッシュファイルを削除する（エラーは無視）
    static func remove(path: String) {
        try? FileManager.default.removeItem(atPath: resolveAbsolutePath(path))
    }

    // MARK: - Path Conversion

    /// 保存済みパス（相対パスまたはレガシー絶対パス）を現在の絶対パスに解決する
    /// ビルド・再インストール時にコンテナ UUID が変わっても正しく解決できる
    static func resolveAbsolutePath(_ storedPath: String) -> String {
        // "/" で始まる場合はレガシーの絶対パス — そのまま返す（後方互換）
        guard !storedPath.hasPrefix("/") else { return storedPath }
        return "\(NSHomeDirectory())/\(storedPath)"
    }

    /// 絶対パスをホームディレクトリからの相対パスに変換する
    static func toRelativePath(_ absolutePath: String) -> String {
        let home = NSHomeDirectory()
        let prefix = home + "/"
        guard absolutePath.hasPrefix(prefix) else { return absolutePath }
        return String(absolutePath.dropFirst(prefix.count))
    }

    // MARK: - Private

    private static func cacheDirectory() throws -> URL {
        // App Group コンテナが利用可能な場合はそちらを優先（Share Extension と共有）
        if let dir = AppGroupContainer.thumbnailsURL {
            return dir
        }
        // フォールバック: アプリのキャッシュディレクトリ
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("thumbnails", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

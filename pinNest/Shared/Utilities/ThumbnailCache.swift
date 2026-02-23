import Foundation
import UIKit

/// URL ピンのサムネイル画像をアプリのキャッシュディレクトリに保存・読み込みするユーティリティ
enum ThumbnailCache {

    // MARK: - Save

    /// 画像データを JPEG として保存し、ファイルパス（絶対パス）を返す
    /// - Parameters:
    ///   - data: 画像データ（JPEG / PNG 等）
    ///   - pinID: 保存先ファイル名に使う Pin の ID
    /// - Returns: 保存したファイルの絶対パス
    static func save(data: Data, for pinID: UUID) throws -> String {
        let dir = try cacheDirectory()
        let fileURL = dir.appendingPathComponent("\(pinID.uuidString).jpg")

        if let uiImage = UIImage(data: data),
           let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
            try jpegData.write(to: fileURL, options: .atomic)
        } else {
            try data.write(to: fileURL, options: .atomic)
        }

        return fileURL.path
    }

    // MARK: - Load

    /// ファイルパスから UIImage をロードする
    static func loadImage(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    // MARK: - Remove

    /// キャッシュファイルを削除する（エラーは無視）
    static func remove(path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    // MARK: - Private

    private static func cacheDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("thumbnails", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

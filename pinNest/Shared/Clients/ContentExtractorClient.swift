import Dependencies
import Foundation
import PDFKit

// MARK: - Errors

enum ContentExtractorError: Error, LocalizedError {
    case unsupportedContentType
    case missingSource
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .unsupportedContentType: "このコンテンツは要約に対応していません。"
        case .missingSource:          "要約するコンテンツが見つかりませんでした。"
        case .emptyContent:           "要約できるテキストがありませんでした。"
        }
    }
}

// MARK: - Client

/// 要約に渡すソーステキストをコンテンツ種別ごとに抽出するクライアント。
/// - URL: ページ HTML を取得してプレーンテキスト化
/// - PDF: PDFKit で全ページのテキストを抽出
/// - テキスト: bodyText をそのまま返す
struct ContentExtractorClient: Sendable {
    /// (contentType, urlString, filePath, bodyText) からソーステキストを抽出する。
    var extract: @Sendable (ContentType, String?, String?, String?) async throws -> String
}

// MARK: - Live

extension ContentExtractorClient: DependencyKey {
    /// URL 取得のタイムアウト（MetadataClient と同方針）
    private static let urlTimeout: TimeInterval = 10

    static let liveValue = ContentExtractorClient(
        extract: { contentType, urlString, filePath, bodyText in
            switch contentType {
            case .text:
                let text = (bodyText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { throw ContentExtractorError.emptyContent }
                return text

            case .url:
                guard let urlString, let url = URL(string: urlString) else {
                    throw ContentExtractorError.missingSource
                }
                let text = try await extractTextFromURL(url, timeout: urlTimeout)
                guard !text.isEmpty else { throw ContentExtractorError.emptyContent }
                return text

            case .pdf:
                guard let filePath else { throw ContentExtractorError.missingSource }
                let absolutePath = ThumbnailCache.resolveAbsolutePath(filePath)
                let text = extractTextFromPDF(at: URL(fileURLWithPath: absolutePath))
                guard let text, !text.isEmpty else { throw ContentExtractorError.emptyContent }
                return text

            case .image, .video:
                throw ContentExtractorError.unsupportedContentType
            }
        }
    )

    static let testValue = ContentExtractorClient(
        extract: unimplemented("\(Self.self).extract", placeholder: "")
    )
}

extension DependencyValues {
    var contentExtractorClient: ContentExtractorClient {
        get { self[ContentExtractorClient.self] }
        set { self[ContentExtractorClient.self] = newValue }
    }
}

// MARK: - Helpers

/// URL から HTML を取得し、スクリプト・スタイル・タグを除去したプレーンテキストを返す。
private func extractTextFromURL(_ url: URL, timeout: TimeInterval) async throws -> String {
    var request = URLRequest(url: url)
    request.timeoutInterval = timeout
    let (data, _) = try await URLSession.shared.data(for: request)
    let html = String(decoding: data, as: UTF8.self)
    return plainText(fromHTML: html)
}

/// PDF の全ページからテキストを抽出する。
private func extractTextFromPDF(at url: URL) -> String? {
    guard let document = PDFDocument(url: url) else { return nil }
    return document.string?.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// 簡易 HTML → プレーンテキスト変換。
/// `<script>` / `<style>` ブロックを丸ごと除去し、残りのタグを剥がして空白を正規化する。
private func plainText(fromHTML html: String) -> String {
    var text = html

    // script / style ブロックを内容ごと削除
    for tag in ["script", "style"] {
        let pattern = "<\(tag)[^>]*>[\\s\\S]*?</\(tag)>"
        text = text.replacingOccurrences(
            of: pattern,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    // 残りの HTML タグを除去
    text = text.replacingOccurrences(
        of: "<[^>]+>",
        with: " ",
        options: .regularExpression
    )

    // HTML エンティティの基本的なデコード
    let entities: [String: String] = [
        "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
        "&quot;": "\"", "&#39;": "'", "&apos;": "'"
    ]
    for (entity, replacement) in entities {
        text = text.replacingOccurrences(of: entity, with: replacement)
    }

    // 連続する空白・改行を 1 つにまとめる
    text = text.replacingOccurrences(
        of: "\\s+",
        with: " ",
        options: .regularExpression
    )

    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}

import Dependencies
import Foundation
import FoundationModels

// MARK: - Availability

/// オンデバイス要約モデルの利用可否。
/// FoundationModels の `SystemLanguageModel.Availability` をアプリ内の Sendable enum に写像する。
enum SummarizationAvailability: Equatable, Sendable {
    case available
    /// 端末が Apple Intelligence 非対応
    case deviceNotEligible
    /// 設定で Apple Intelligence が未有効
    case intelligenceNotEnabled
    /// モデル準備中（ダウンロード中など）
    case modelNotReady
    /// その他の理由で利用不可
    case unsupported

    /// ユーザー向けの説明文（非対応時にボタン下へ表示する）
    var unavailableMessage: String? {
        switch self {
        case .available:               nil
        case .deviceNotEligible:       "この端末は Apple Intelligence に対応していません。"
        case .intelligenceNotEnabled:  "設定で Apple Intelligence をオンにすると要約を利用できます。"
        case .modelNotReady:           "要約モデルを準備中です。しばらくしてからお試しください。"
        case .unsupported:             "この端末では要約機能を利用できません。"
        }
    }
}

// MARK: - Errors

enum SummarizationError: Error, LocalizedError {
    case unavailable
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .unavailable: "要約モデルを利用できません。"
        case .emptyInput:  "要約するテキストがありません。"
        }
    }
}

// MARK: - Client

struct SummarizationClient: Sendable {
    /// 要約モデルの利用可否を返す。
    var availability: @Sendable () -> SummarizationAvailability
    /// 与えられたテキストを日本語で要約して返す。
    var summarize: @Sendable (String) async throws -> String
}

// MARK: - Live

extension SummarizationClient: DependencyKey {
    /// 要約品質と context 上限のバランスから、入力テキストはこの文字数まで切り詰める。
    private static let maxInputCharacters = 6_000

    static let liveValue = SummarizationClient(
        availability: {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case let .unavailable(reason):
                switch reason {
                case .deviceNotEligible:        return .deviceNotEligible
                case .appleIntelligenceNotEnabled: return .intelligenceNotEnabled
                case .modelNotReady:            return .modelNotReady
                @unknown default:               return .unsupported
                }
            @unknown default:
                return .unsupported
            }
        },
        summarize: { rawText in
            let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw SummarizationError.emptyInput }
            guard case .available = SystemLanguageModel.default.availability else {
                throw SummarizationError.unavailable
            }

            // context 上限対策として先頭を切り詰める
            let truncated = text.count > maxInputCharacters
                ? String(text.prefix(maxInputCharacters))
                : text

            let session = LanguageModelSession(
                instructions: """
                あなたは優秀な要約アシスタントです。
                与えられたコンテンツを日本語で簡潔に要約してください。
                - 重要なポイントを3〜5行程度にまとめる
                - 箇条書きではなく自然な文章で書く
                - 元の言語が何であっても要約は日本語で出力する
                """
            )
            let response = try await session.respond(to: truncated)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    )

    static let testValue = SummarizationClient(
        availability: { .available },
        summarize: unimplemented("\(Self.self).summarize", placeholder: "")
    )
}

extension DependencyValues {
    var summarizationClient: SummarizationClient {
        get { self[SummarizationClient.self] }
        set { self[SummarizationClient.self] = newValue }
    }
}

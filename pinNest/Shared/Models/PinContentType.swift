import Foundation

// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor 環境で computed property が
// @MainActor に隔離されないよう nonisolated を明示する。
// Identifiable は @MainActor 隔離との競合が生じるため、ForEach では id: \.self を使う。
enum PinContentType: CaseIterable, Equatable, Hashable, Sendable {
    case url, image, video, pdf, text

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
}

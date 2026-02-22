import Foundation

// SwiftUI を import しないことで @MainActor 隔離を防ぎ、
// Equatable / Hashable / Sendable を非隔離で合成できるようにする。
enum PinContentType: CaseIterable, Identifiable, Equatable, Hashable, Sendable {
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

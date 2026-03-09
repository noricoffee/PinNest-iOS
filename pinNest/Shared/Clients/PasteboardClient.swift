import ComposableArchitecture
import UIKit

// MARK: - PasteboardClient

struct PasteboardClient: Sendable {
    var copy: @Sendable (String) -> Void
}

extension PasteboardClient: DependencyKey {
    static let liveValue = PasteboardClient(
        copy: { string in
            UIPasteboard.general.string = string
        }
    )

    static let testValue = PasteboardClient(
        copy: { _ in }
    )
}

extension DependencyValues {
    var pasteboardClient: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

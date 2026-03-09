import SwiftUI

// MARK: - PinContextMenuModifier

struct PinContextMenuModifier: ViewModifier {
    let onShare: () -> Void
    let onAddTag: () -> Void
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content.contextMenu {
            Button { onShare() } label: {
                Label("共有", systemImage: "square.and.arrow.up")
            }
            Button { onAddTag() } label: {
                Label("タグを追加", systemImage: "tag")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func pinContextMenu(
        onShare: @escaping () -> Void,
        onAddTag: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(PinContextMenuModifier(
            onShare: onShare,
            onAddTag: onAddTag,
            onDelete: onDelete
        ))
    }
}

import SwiftUI

// MARK: - PinMenuAction

/// コンテキストメニューの各項目を表すデータモデル。
/// メニュー項目を事前に配列として構築し、`.contextMenu` 内では
/// `ForEach` のみで描画することで `_ConditionalContent` の生成を回避する。
struct PinMenuAction: Identifiable {
    let id: String
    let label: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void

    /// `contentType` に基づいてメニュー項目の配列を事前構築する。
    /// 分岐はここ（View body 評価時）で完了し、`.contextMenu` 内には持ち込まない。
    static func actions(
        contentType: ContentType,
        onOpenLink: @escaping () -> Void,
        onCopyLink: @escaping () -> Void,
        onCopyBody: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onAddTag: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> [PinMenuAction] {
        var items: [PinMenuAction] = []

        switch contentType {
        case .url:
            items.append(.init(id: "openLink", label: "リンクを開く", icon: "safari", isDestructive: false, action: onOpenLink))
            items.append(.init(id: "copyLink", label: "リンクをコピー", icon: "link", isDestructive: false, action: onCopyLink))
        case .text:
            items.append(.init(id: "copyBody", label: "本文をコピー", icon: "doc.on.doc", isDestructive: false, action: onCopyBody))
        case .image, .video, .pdf:
            break
        }

        items.append(.init(id: "share", label: "共有", icon: "square.and.arrow.up", isDestructive: false, action: onShare))
        items.append(.init(id: "addTag", label: "タグを追加", icon: "tag", isDestructive: false, action: onAddTag))
        items.append(.init(id: "delete", label: "削除", icon: "trash", isDestructive: true, action: onDelete))

        return items
    }
}

// MARK: - PinContextMenuModifier

/// `.contextMenu` 内に `if`/`switch` 分岐を一切入れず、
/// `ForEach` のみで描画するモディファイア。
struct PinContextMenuModifier: ViewModifier {
    let menuItems: [PinMenuAction]

    func body(content: Content) -> some View {
        content.contextMenu {
            ForEach(menuItems) { item in
                Button(role: item.isDestructive ? .destructive : nil) {
                    item.action()
                } label: {
                    Label(item.label, systemImage: item.icon)
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func pinContextMenu(_ items: [PinMenuAction]) -> some View {
        modifier(PinContextMenuModifier(menuItems: items))
    }
}

import SwiftUI

/// 画像・動画・PDF ビューアの共通ラッパー。
/// - NavigationStack + topBarTrailing xmark ボタン
/// - 上から下スワイプで dismiss（100pt 超でリリース時）
struct MediaViewerView<Content: View>: View {
    let title: String
    let darkToolbar: Bool
    let content: () -> Content

    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0

    init(
        title: String = "",
        darkToolbar: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.darkToolbar = darkToolbar
        self.content = content
    }

    var body: some View {
        NavigationStack {
            contentWithToolbarStyle
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                        }
                        .accessibilityLabel("閉じる")
                    }
                }
        }
        .offset(y: max(dragOffset, 0))
        .animation(.interactiveSpring, value: dragOffset)
        .gesture(swipeToDismissGesture)
    }

    @ViewBuilder
    private var contentWithToolbarStyle: some View {
        if darkToolbar {
            content()
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            content()
        }
    }

    private var swipeToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($dragOffset) { value, state, _ in
                guard value.translation.height > 0 else { return }
                state = value.translation.height
            }
            .onEnded { value in
                if value.translation.height > 100 { dismiss() }
            }
    }
}

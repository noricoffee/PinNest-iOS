import ComposableArchitecture
import SwiftUI

struct PinListView: View {
    @Bindable var store: StoreOf<PinListReducer>
    @Environment(\.colorSchemePreference) private var colorSchemePreference

    // MARK: - Body

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationTitle("Pinnest")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.send(.settingsButtonTapped)
                        } label: {
                            Image(systemName: "gearshape")
                                .accessibilityLabel("設定")
                        }
                    }
                }
                .onAppear {
                    store.send(.onAppear)
                }
                .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
                    PinDetailView(store: detailStore)
                        .preferredColorScheme(colorSchemePreference.colorScheme)
                }
                .sheet(item: $store.scope(state: \.contextMenu.tagPicker, action: \.contextMenu.tagPicker)) { pickerStore in
                    TagPickerView(store: pickerStore)
                        .preferredColorScheme(colorSchemePreference.colorScheme)
                }
                .alert(
                    "ピンを削除しますか？",
                    isPresented: Binding(
                        get: { store.contextMenu.isDeleteAlertPresented },
                        set: { if !$0 { store.send(.contextMenu(.deleteAlertDismissed)) } }
                    )
                ) {
                    Button("削除", role: .destructive) {
                        store.send(.contextMenu(.deleteConfirmed))
                    }
                    Button("キャンセル", role: .cancel) {
                        store.send(.contextMenu(.deleteAlertDismissed))
                    }
                } message: {
                    Text("この操作は取り消せません。")
                }
                .sheet(
                    isPresented: Binding(
                        get: { store.contextMenu.isShareSheetPresented },
                        set: { if !$0 { store.send(.contextMenu(.shareSheetDismissed)) } }
                    )
                ) {
                    ShareSheet(items: store.contextMenu.shareItems)
                        .presentationDetents([.medium, .large])
                }
                .alert(
                    "読み込みエラー",
                    isPresented: Binding(
                        get: { store.errorMessage != nil },
                        set: { if !$0 { store.send(.errorAlertDismissed) } }
                    )
                ) {
                    Button("OK", role: .cancel) {
                        store.send(.errorAlertDismissed)
                    }
                } message: {
                    Text(store.errorMessage ?? "")
                }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterChips
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if store.filteredPins.isEmpty {
                    emptyState
                } else {
                    masonryGrid
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pin.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("ピンがありません")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("右下の + ボタンからピンを追加してみましょう")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "すべて", isSelected: store.selectedFilter == nil) {
                    store.send(.filterSelected(nil))
                }
                ForEach(ContentType.allCases, id: \.self) { type in
                    FilterChip(
                        label: type.label,
                        icon: type.iconName,
                        isSelected: store.selectedFilter == type
                    ) {
                        store.send(.filterSelected(type))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Masonry Grid

    private var masonryGrid: some View {
        MasonryLayout(columns: 2, spacing: 12) {
            ForEach(store.filteredPins, id: \.id) { pin in
                Button {
                    store.send(.pinTapped(pin))
                } label: {
                    PinCardView(pin: pin) {
                        store.send(.favoriteButtonTapped(pin))
                    }
                    .pinContextMenu(PinMenuAction.actions(
                        contentType: pin.contentType,
                        onOpenLink: { store.send(.contextMenu(.openLinkTapped(pin))) },
                        onCopyLink: { store.send(.contextMenu(.copyLinkTapped(pin))) },
                        onCopyBody: { store.send(.contextMenu(.copyBodyTapped(pin))) },
                        onShare: { store.send(.contextMenu(.shareTapped(pin))) },
                        onAddTag: { store.send(.contextMenu(.addTagTapped(pin))) },
                        onDelete: { store.send(.contextMenu(.deleteTapped(pin))) }
                    ))
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(pin.title)
            }
        }
    }
}

// MARK: - MasonryLayout

private struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 12

    struct Cache {
        var placements: [(x: CGFloat, y: CGFloat)]
        var totalHeight: CGFloat
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache(placements: [], totalHeight: 0)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let totalWidth = proposal.width ?? 300
        let columnWidth = (totalWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = Array(repeating: CGFloat(0), count: columns)
        var placements: [(x: CGFloat, y: CGFloat)] = []

        for subview in subviews {
            let col = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) ?? 0
            placements.append((x: CGFloat(col) * (columnWidth + spacing), y: columnHeights[col]))
            columnHeights[col] += subview.sizeThatFits(.init(width: columnWidth, height: nil)).height + spacing
        }

        let totalHeight = subviews.isEmpty ? 0 : (columnHeights.max() ?? 0) - spacing
        cache.placements = placements
        cache.totalHeight = totalHeight
        return CGSize(width: totalWidth, height: max(totalHeight, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let columnWidth = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        for (index, subview) in subviews.enumerated() {
            guard index < cache.placements.count else { continue }
            let p = cache.placements[index]
            let measuredHeight = subview.sizeThatFits(.init(width: columnWidth, height: nil)).height
            subview.place(
                at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y),
                proposal: .init(width: columnWidth, height: measuredHeight)
            )
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.medium))
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview {
    PinListView(store: Store(initialState: PinListReducer.State()) {
        PinListReducer()
    })
}

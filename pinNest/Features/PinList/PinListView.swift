import ComposableArchitecture
import SwiftUI

struct PinListView: View {
    @Bindable var store: StoreOf<PinListReducer>
    @Environment(\.colorSchemePreference) private var colorSchemePreference

    // MARK: - Body

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationTitle("pinNest")
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
            .padding(.vertical, 2)
        }
    }

    // MARK: - Masonry Grid

    private var masonryGrid: some View {
        let pins = store.filteredPins
        let columns = splitIntoColumns(pins, count: 2)
        return HStack(alignment: .top, spacing: 12) {
            columnView(pins: columns[0])
            columnView(pins: columns[1])
        }
    }

    private func columnView(pins: [Pin]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(pins, id: \.id) { pin in
                Button {
                    store.send(.pinTapped(pin))
                } label: {
                    PinCardView(pin: pin)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(pin.title)
            }
        }
    }

    private func splitIntoColumns(_ pins: [Pin], count: Int) -> [[Pin]] {
        var result = Array(repeating: [Pin](), count: count)
        for (index, pin) in pins.enumerated() {
            result[index % count].append(pin)
        }
        return result
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

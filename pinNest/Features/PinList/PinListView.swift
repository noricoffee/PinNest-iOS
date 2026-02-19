import SwiftUI

struct PinListView: View {
    @State private var selectedFilter: PinContentType? = nil
    @State private var selectedTab: TabItem = .home

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                scrollContent
                floatingBar
            }
            .navigationTitle("pinNest")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterChips
                masonryGrid
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "すべて", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(PinContentType.allCases, id: \.self) { type in
                    FilterChip(
                        label: type.label,
                        icon: type.iconName,
                        isSelected: selectedFilter == type
                    ) {
                        selectedFilter = type
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Masonry Grid

    private var filteredItems: [PinPreviewItem] {
        guard let filter = selectedFilter else { return PinPreviewItem.samples }
        return PinPreviewItem.samples.filter { $0.contentType == filter }
    }

    private var masonryGrid: some View {
        let columns = splitIntoColumns(filteredItems, count: 2)
        return HStack(alignment: .top, spacing: 12) {
            columnView(items: columns[0])
            columnView(items: columns[1])
        }
    }

    private func columnView(items: [PinPreviewItem]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { item in
                PinCardView(item: item)
            }
        }
    }

    private func splitIntoColumns(_ items: [PinPreviewItem], count: Int) -> [[PinPreviewItem]] {
        var result = Array(repeating: [PinPreviewItem](), count: count)
        for (index, item) in items.enumerated() {
            result[index % count].append(item)
        }
        return result
    }

    // MARK: - Floating Bar

    private var floatingBar: some View {
        HStack(alignment: .center, spacing: 12) {
            tabBar
            fabButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 36)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                label: "ホーム",
                isSelected: selectedTab == .home
            ) { selectedTab = .home }

            TabBarButton(
                icon: "clock.fill",
                label: "履歴",
                isSelected: selectedTab == .history
            ) { selectedTab = .history }

            TabBarButton(
                icon: "magnifyingglass",
                label: "検索",
                isSelected: selectedTab == .search
            ) { selectedTab = .search }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
    }

    private var fabButton: some View {
        Button {
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.accentColor.opacity(0.45), radius: 10, y: 4)
        }
        .accessibilityLabel("ピンを追加")
    }

    // MARK: - TabItem

    private enum TabItem {
        case home, history, search
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

// MARK: - TabBarButton

private struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(minWidth: 72, minHeight: 44)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview {
    PinListView()
}

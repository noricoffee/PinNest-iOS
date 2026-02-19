import SwiftUI

struct PinListView: View {
    @State private var selectedFilter: PinContentType? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            scrollContent
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
            .padding(.bottom, 80)
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
    PinListView()
}

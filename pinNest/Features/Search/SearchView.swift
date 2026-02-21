import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationTitle("検索")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "タイトル・本文で検索"
                )
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var scrollContent: some View {
        if searchText.isEmpty {
            emptyPrompt
        } else if filteredItems.isEmpty {
            noResultsView
        } else {
            resultGrid
        }
    }

    private var emptyPrompt: some View {
        ContentUnavailableView(
            "ピンを検索",
            systemImage: "magnifyingglass",
            description: Text("タイトル・メモ・本文のキーワードで\n部分一致検索できます")
        )
    }

    private var noResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }

    // MARK: - Filtered Items

    private var filteredItems: [PinPreviewItem] {
        let query = searchText.lowercased()
        return PinPreviewItem.samples.filter { item in
            item.title.lowercased().contains(query)
                || (item.subtitle?.lowercased().contains(query) ?? false)
                || (item.previewText?.lowercased().contains(query) ?? false)
        }
    }

    // MARK: - Result Grid

    private var resultGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(filteredItems.count)件")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                masonryGrid
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
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

// MARK: - Preview

#Preview {
    SearchView()
}

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
        } else {
            noResultsView
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
}

// MARK: - Preview

#Preview {
    SearchView()
}

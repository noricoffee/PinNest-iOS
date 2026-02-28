import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchReducer>
    @Environment(\.colorSchemePreference) private var colorSchemePreference

    // MARK: - Body

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationTitle("検索")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $store.searchText.sending(\.searchTextChanged),
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "タイトル・本文で検索"
                )
                .onAppear {
                    store.send(.onAppear)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortOrderMenu
                    }
                }
                .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
                    PinDetailView(store: detailStore)
                        .preferredColorScheme(colorSchemePreference.colorScheme)
                }
        }
    }

    // MARK: - Scroll Content

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !store.allTags.isEmpty {
                    tagFilterBar
                }
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if store.results.isEmpty {
                    ContentUnavailableView.search(text: store.searchText)
                } else {
                    masonryGrid
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 64)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Tag Filter Bar

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.allTags) { tag in
                    let isSelected = store.selectedTagIds.contains(tag.id)
                    Button {
                        store.send(.tagFilterToggled(tag.id))
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                            } else if tag.id == TagItem.favoriteID {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                            }
                            Text(tag.id == TagItem.favoriteID ? tag.name : "#\(tag.name)")
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
                    .accessibilityLabel(isSelected ? "\(tag.name) フィルター選択中" : "\(tag.name) でフィルター")
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Sort Menu

    private var sortOrderMenu: some View {
        Menu {
            ForEach(PinSortOrder.allCases, id: \.self) { order in
                Button {
                    store.send(.sortOrderChanged(order))
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if store.sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(store.sortOrder.rawValue, systemImage: "arrow.up.arrow.down")
                .font(.subheadline)
        }
        .accessibilityLabel("並び替え")
    }

    // MARK: - Masonry Grid

    private var masonryGrid: some View {
        let pins = store.results
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

// MARK: - Preview

#Preview {
    SearchView(store: Store(initialState: SearchReducer.State()) {
        SearchReducer()
    })
}

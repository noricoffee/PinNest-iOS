import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: TabItem.home) {
                PinListView()
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(value: TabItem.history) {
                HistoryView()
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(value: TabItem.search) {
                SearchView()
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingBar
        }
    }

    // MARK: - Floating Bar

    private var floatingBar: some View {
        HStack(alignment: .center, spacing: 12) {
            mainTabGroup
            fabButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // 左グループ: ホーム + 履歴 + 検索を1つのガラスカプセルに
    private var mainTabGroup: some View {
        HStack(spacing: 4) {
            tabPill(.home, icon: "house.fill", label: "ホーム")
            tabPill(.history, icon: "clock.fill", label: "履歴")
            tabPill(.search, icon: "magnifyingglass", label: "検索")
        }
        .padding(4)
        .glassEffect(in: Capsule())
        .contextMenu {
            Button("ホーム", systemImage: "house.fill") { selectedTab = .home }
            Button("履歴", systemImage: "clock.fill") { selectedTab = .history }
            Button("検索", systemImage: "magnifyingglass") { selectedTab = .search }
        }
    }

    private func tabPill(_ tab: TabItem, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        return Button { selectedTab = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .frame(minWidth: 64, minHeight: 44)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            // 選択中は内側に白いピル背景（写真アプリスタイル）
            .background(
                isSelected ? Color(.systemBackground).opacity(0.85) : .clear,
                in: Capsule()
            )
        }
        .accessibilityLabel(label)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
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

    enum TabItem: Hashable {
        case home, history, search
    }
}

#Preview {
    ContentView()
}

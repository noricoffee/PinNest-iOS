import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var isFABExpanded = false
    @State private var createContentType: PinContentType? = nil

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
        // 暗転オーバーレイ（タップで閉じる）
        .overlay {
            if isFABExpanded {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) { isFABExpanded = false }
                    }
                    .transition(.opacity)
            }
        }
        // タイプ選択メニュー（FAB の上に展開）
        .overlay(alignment: .bottomTrailing) {
            if isFABExpanded {
                fabTypeMenu
                    .padding(.trailing, 20)
                    .padding(.bottom, 80) // floating bar height (8 top + 56 content + 16 bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: isFABExpanded)
        .sheet(item: $createContentType) { type in
            PinCreateView(contentType: type)
        }
    }

    // MARK: - Floating Bar

    private var floatingBar: some View {
        HStack(alignment: .center, spacing: 12) {
            mainTabGroup
            Spacer()
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
            withAnimation(.spring(duration: 0.3)) { isFABExpanded.toggle() }
        } label: {
            Image(systemName: isFABExpanded ? "xmark" : "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    isFABExpanded ? Color(.systemGray) : Color.accentColor,
                    in: Circle()
                )
                .shadow(
                    color: Color.accentColor.opacity(isFABExpanded ? 0 : 0.45),
                    radius: 10, y: 4
                )
        }
        .accessibilityLabel(isFABExpanded ? "閉じる" : "ピンを追加")
    }

    // MARK: - FAB Type Menu

    private var fabTypeMenu: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(Array(PinContentType.allCases.reversed())) { type in
                fabTypeMenuItem(type: type)
            }
        }
    }

    private func fabTypeMenuItem(type: PinContentType) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { isFABExpanded = false }
            createContentType = type
        } label: {
            HStack(spacing: 12) {
                Text(type.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Image(systemName: type.iconName)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor, in: Circle())
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .glassEffect(in: Capsule())
        }
        .accessibilityLabel("\(type.label)を追加")
    }

    // MARK: - TabItem

    enum TabItem: Hashable {
        case home, history, search
    }
}

#Preview {
    ContentView()
}

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>

    // MARK: - Body

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            Tab(value: AppReducer.Tab.home) {
                PinListView()
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(value: AppReducer.Tab.history) {
                HistoryView()
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(value: AppReducer.Tab.search) {
                SearchView()
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingBar
        }
        // 暗転オーバーレイ（タップで閉じる）
        .overlay {
            if store.isFABExpanded {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.overlayTapped, animation: .spring(duration: 0.3))
                    }
                    .transition(.opacity)
            }
        }
        // タイプ選択メニュー（FAB の上に展開）
        .overlay(alignment: .bottomTrailing) {
            if store.isFABExpanded {
                fabTypeMenu
                    .padding(.trailing, 20)
                    .padding(.bottom, 80) // floating bar height (8 top + 56 content + 16 bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: store.isFABExpanded)
        .sheet(
            isPresented: Binding(
                get: { store.createContentType != nil },
                set: { if !$0 { store.send(.createSheetDismissed) } }
            )
        ) {
            if let type = store.createContentType {
                PinCreateView(contentType: type)
            }
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
            Button("ホーム", systemImage: "house.fill") {
                store.send(.tabSelected(.home))
            }
            Button("履歴", systemImage: "clock.fill") {
                store.send(.tabSelected(.history))
            }
            Button("検索", systemImage: "magnifyingglass") {
                store.send(.tabSelected(.search))
            }
        }
    }

    private func tabPill(_ tab: AppReducer.Tab, icon: String, label: String) -> some View {
        let isSelected = store.selectedTab == tab
        return Button {
            store.send(.tabSelected(tab))
        } label: {
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
        .animation(.easeInOut(duration: 0.2), value: store.selectedTab)
    }

    private var fabButton: some View {
        Button {
            store.send(.fabButtonTapped, animation: .spring(duration: 0.3))
        } label: {
            Image(systemName: store.isFABExpanded ? "xmark" : "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    store.isFABExpanded ? Color(.systemGray) : Color.accentColor,
                    in: Circle()
                )
                .shadow(
                    color: Color.accentColor.opacity(store.isFABExpanded ? 0 : 0.45),
                    radius: 10, y: 4
                )
        }
        .accessibilityLabel(store.isFABExpanded ? "閉じる" : "ピンを追加")
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
            store.send(.fabMenuItemTapped(type), animation: .spring(duration: 0.3))
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
}

#Preview {
    AppView(store: Store(initialState: AppReducer.State()) {
        AppReducer()
    })
}

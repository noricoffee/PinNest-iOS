import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>

    // MARK: - Body

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            Tab(value: AppReducer.Tab.home) {
                PinListView(store: store.scope(state: \.pinList, action: \.pinList))
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(value: AppReducer.Tab.history) {
                HistoryView(store: store.scope(state: \.history, action: \.history))
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(value: AppReducer.Tab.search) {
                SearchView(store: store.scope(state: \.search, action: \.search))
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
        // タイプ選択メニュー（FAB 中心から放射状に展開）
        .overlay(alignment: .bottomTrailing) {
            fabRadialMenu
                .padding(.trailing, 48)  // 20 (bar trailing padding) + 28 (half FAB)
                .padding(.bottom, 80)    // floating bar height ≈ FAB center from overlay bottom
        }
        .animation(.spring(duration: 0.3), value: store.isFABExpanded)
        .preferredColorScheme(store.colorSchemePreference.colorScheme)
        .sheet(item: $store.scope(state: \.pinCreate, action: \.create)) { createStore in
            PinCreateView(store: createStore)
        }
        .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
            SettingsView(store: settingsStore)
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

    // MARK: - FAB Radial Menu

    private var fabRadialMenu: some View {
        let types = ContentType.allCases
        let count = types.count
        let startAngle: Double = 90.0   // 真上 (12時方向)
        let endAngle: Double = 180.0   // 真左 (9時方向)
        let radius: CGFloat = 170      // 64pt アイテムが重ならない半径 (間隔≈67pt)

        return ZStack {
            ForEach(Array(types.enumerated()), id: \.element) { index, type in
                let fraction = count > 1 ? Double(index) / Double(count - 1) : 0.0
                let angleDeg = startAngle + fraction * (endAngle - startAngle)
                let angleRad = angleDeg * .pi / 180.0
                // SwiftUI は y 軸が下向きのため dy は反転
                let dx = CGFloat(cos(angleRad)) * radius
                let dy = -CGFloat(sin(angleRad)) * radius

                fabRadialItem(type: type)
                    .offset(
                        x: store.isFABExpanded ? dx : 0,
                        y: store.isFABExpanded ? dy : 0
                    )
                    .scaleEffect(store.isFABExpanded ? 1.0 : 0.1)
                    .opacity(store.isFABExpanded ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.70)
                            .delay(store.isFABExpanded ? Double(index) * 0.05 : 0),
                        value: store.isFABExpanded
                    )
            }
        }
        .frame(width: 0, height: 0)  // ゼロサイズアンカー（FAB 中心に対応）
        .allowsHitTesting(store.isFABExpanded)
    }

    private func fabRadialItem(type: ContentType) -> some View {
        Button {
            store.send(.fabMenuItemTapped(type))
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, y: 4)
                VStack(spacing: 2) {
                    Image(systemName: type.iconName)
                        .font(.body.weight(.semibold))
                    Text(type.label)
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("\(type.label)を追加")
    }
}

#Preview {
    AppView(store: Store(initialState: AppReducer.State()) {
        AppReducer()
    })
}

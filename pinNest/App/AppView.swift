import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var shouldReduceMotion: Bool {
        systemReduceMotion || store.reduceMotion
    }

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
        // 暗転＋ラジアルメニューを同一 overlay に統合
        // （別 overlay に分離するとラジアルアイテムが zero-size frame の外に描画され、
        //   ヒットテストが暗転 onTapGesture に先取りされて二重発火の遅延が生じる）
        .overlay {
            ZStack {
                if store.isFABExpanded {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            store.send(.overlayTapped, animation: shouldReduceMotion ? nil : .spring(duration: 0.3))
                        }
                        .transition(shouldReduceMotion ? .identity : .opacity.animation(.easeOut(duration: 0.15)))
                }
                // ラジアルメニュー（ZStack 内で後に描画 = Z 上位 = ヒットテスト優先）
                GeometryReader { geo in
                    fabRadialMenu(in: geo)
                }
                .allowsHitTesting(store.isFABExpanded)
            }
        }
        .preferredColorScheme(store.colorSchemePreference.colorScheme)
        .environment(\.colorSchemePreference, store.colorSchemePreference)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.send(.sceneDidBecomeActive)
            }
        }
        .sheet(item: $store.scope(state: \.pinCreate, action: \.create)) { createStore in
            PinCreateView(store: createStore)
                .preferredColorScheme(store.colorSchemePreference.colorScheme)
        }
        .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
            SettingsView(store: settingsStore)
                .preferredColorScheme(store.colorSchemePreference.colorScheme)
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
        .animation(shouldReduceMotion ? nil : .easeInOut(duration: 0.2), value: store.selectedTab)
    }

    private var fabButton: some View {
        Button {
            store.send(.fabButtonTapped, animation: shouldReduceMotion ? nil : .spring(duration: 0.3))
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
        // sheet presentation に影響させないよう body 全体ではなく FAB のみにアニメーションを適用
        .animation(shouldReduceMotion ? nil : .spring(duration: 0.3), value: store.isFABExpanded)
    }

    // MARK: - FAB Radial Menu

    /// GeometryReader 内で .position() を使い絶対座標配置することで
    /// ヒットテストが zero-size frame の外に出ず、暗転との競合が起きない
    private func fabRadialMenu(in geo: GeometryProxy) -> some View {
        let types = ContentType.allCases
        let count = types.count
        let startAngle: Double = 90.0   // 真上 (12時方向)
        let endAngle: Double = 180.0    // 真左 (9時方向)
        let radius: CGFloat = 170       // 64pt アイテムが重ならない半径 (間隔≈67pt)
        // overlay は safeAreaInset を含む全域をカバーするため
        // geo.size = フルスクリーンサイズ。FAB 中心 ≈ (width-48, height-80)
        let fabX = geo.size.width - 48
        let fabY = geo.size.height - 80

        return ZStack {
            ForEach(Array(types.enumerated()), id: \.element) { index, type in
                let fraction = count > 1 ? Double(index) / Double(count - 1) : 0.0
                let angleDeg = startAngle + fraction * (endAngle - startAngle)
                let angleRad = angleDeg * .pi / 180.0
                // SwiftUI は y 軸が下向きのため dy は反転
                let dx = CGFloat(cos(angleRad)) * radius
                let dy = -CGFloat(sin(angleRad)) * radius

                fabRadialItem(type: type)
                    .position(
                        x: fabX + (store.isFABExpanded ? dx : 0),
                        y: fabY + (store.isFABExpanded ? dy : 0)
                    )
                    .scaleEffect(store.isFABExpanded ? 1.0 : 0.1)
                    .opacity(store.isFABExpanded ? 1.0 : 0.0)
                    .animation(
                        shouldReduceMotion ? nil :
                            store.isFABExpanded
                                ? .spring(response: 0.35, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.03)
                                : .spring(response: 0.2, dampingFraction: 0.9),
                        value: store.isFABExpanded
                    )
            }
        }
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

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var tabBarGlobalFrame: CGRect? = nil

    private var shouldReduceMotion: Bool {
        systemReduceMotion || store.reduceMotion
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            Tab("ホーム", systemImage: "house.fill", value: AppReducer.Tab.home) {
                PinListView(store: store.scope(state: \.pinList, action: \.pinList))
            }
            Tab("履歴", systemImage: "clock.fill", value: AppReducer.Tab.history) {
                HistoryView(store: store.scope(state: \.history, action: \.history))
            }
            Tab("検索", systemImage: "magnifyingglass", value: AppReducer.Tab.search, role: .search) {
                SearchView(store: store.scope(state: \.search, action: \.search))
            }
        }
        // UIKit の UITabBarController.tabBar.frame を取得して FAB の配置に使う
        .background {
            TabBarFrameReader { frame in
                tabBarGlobalFrame = frame
            }
        }
        // 暗転・ラジアルメニュー・FAB を一つの overlay で管理
        .overlay {
            GeometryReader { geo in
                let originY = geo.frame(in: .global).minY

                ZStack {
                    // 暗転
                    if store.isFABExpanded {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture {
                                store.send(.overlayTapped, animation: shouldReduceMotion ? nil : .spring(duration: 0.3))
                            }
                            .transition(shouldReduceMotion ? .identity : .opacity.animation(.easeOut(duration: 0.15)))
                    }

                    if let tabFrame = tabBarGlobalFrame {
                        let originX = geo.frame(in: .global).minX
                        // tabFrame は _UITabBarAuxiliaryView（検索ボタン）の global frame
                        // FAB は検索ボタンの上端から 8pt 上に独立して配置
                        let fabSize = tabFrame.height
                        let gap: CGFloat = 8
                        let fabX = tabFrame.midX - originX
                        let fabY = tabFrame.minY - originY - gap - fabSize / 2

                        ZStack {
                            fabRadialItems(fabX: fabX, fabY: fabY)
                                .allowsHitTesting(store.isFABExpanded)
                            fabButton(size: fabSize)
                                .position(x: fabX, y: fabY)
                        }
                        .transition(.opacity)
                    }
                }
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

    // MARK: - FAB Button

    private func fabButton(size: CGFloat) -> some View {
        Button {
            store.send(.fabButtonTapped, animation: shouldReduceMotion ? nil : .spring(duration: 0.3))
        } label: {
            ZStack {
                Circle()
                    .fill(store.isFABExpanded ? Color(.secondarySystemBackground) : Color.accentColor)
                Image(systemName: store.isFABExpanded ? "xmark" : "plus")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(store.isFABExpanded ? Color.primary : Color.white)
            }
            .frame(width: size, height: size)
        }
        .accessibilityLabel(store.isFABExpanded ? "閉じる" : "ピンを追加")
        .animation(shouldReduceMotion ? nil : .spring(duration: 0.3), value: store.isFABExpanded)
    }

    // MARK: - FAB Radial Menu

    private func fabRadialItems(fabX: CGFloat, fabY: CGFloat) -> some View {
        let types = ContentType.allCases
        let count = types.count
        let startAngle: Double = 90.0
        let endAngle:   Double = 180.0
        let radius:     CGFloat = 170

        return ZStack {
            ForEach(Array(types.enumerated()), id: \.element) { index, type in
                let fraction = count > 1 ? Double(index) / Double(count - 1) : 0.0
                let angleDeg = startAngle + fraction * (endAngle - startAngle)
                let angleRad = angleDeg * .pi / 180.0
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

// MARK: - TabBar Frame Reader

private struct TabBarFrameReader: UIViewRepresentable {
    var onFrame: (CGRect) -> Void

    func makeUIView(context: Context) -> InspectorView {
        InspectorView(onFrame: onFrame)
    }

    func updateUIView(_ uiView: InspectorView, context: Context) {
        uiView.onFrame = onFrame
    }

    // Tab(role: .search) ボタン（_UITabBarAuxiliaryView）の global frame を通知する
    final class InspectorView: UIView {
        var onFrame: (CGRect) -> Void
        private var lastFrame: CGRect = .zero

        init(onFrame: @escaping (CGRect) -> Void) {
            self.onFrame = onFrame
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            findAndReport()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            findAndReport()
        }

        private func findAndReport() {
            // 方法1: レスポンダチェーンから UITabBarController を探す
            var r: UIResponder? = self
            while let cur = r {
                if let tabVC = cur as? UITabBarController {
                    reportWithCapsule(tabVC.tabBar)
                    return
                }
                r = cur.next
            }
            // 方法2: WindowScene → rootViewController 階層から探す
            guard let windowScene = window?.windowScene else { return }
            for win in windowScene.windows {
                if let tabVC = findTabBarController(from: win.rootViewController) {
                    reportWithCapsule(tabVC.tabBar)
                    return
                }
                if let tabBar = findTabBarView(in: win) {
                    reportWithCapsule(tabBar)
                    return
                }
            }
        }

        private func reportWithCapsule(_ tabBar: UITabBar) {
            // Tab(role: .search) のボタン（正方形の補助ビュー）を探してそのフレームを使う
            // UITabBar の直接サブビューのうち、正方形かつ全幅の半分より小さいものが検索ボタン
            for sub in tabBar.subviews {
                let frame = sub.convert(sub.bounds, to: nil)
                if !frame.isEmpty,
                   abs(frame.width - frame.height) < 2,
                   frame.width < tabBar.bounds.width * 0.5 {
                    report(frame)
                    return
                }
            }
            // フォールバック: TabBar 全体のフレーム
            report(tabBar.convert(tabBar.bounds, to: nil))
        }

        private func report(_ frame: CGRect) {
            guard !frame.isEmpty, frame != lastFrame else { return }
            lastFrame = frame
            onFrame(frame)
        }

        private func findTabBarController(from vc: UIViewController?) -> UITabBarController? {
            guard let vc else { return nil }
            if let tabVC = vc as? UITabBarController { return tabVC }
            for child in vc.children {
                if let found = findTabBarController(from: child) { return found }
            }
            return nil
        }

        private func findTabBarView(in view: UIView) -> UITabBar? {
            if let tabBar = view as? UITabBar { return tabBar }
            for sub in view.subviews {
                if let found = findTabBarView(in: sub) { return found }
            }
            return nil
        }
    }
}

#Preview {
    AppView(store: Store(initialState: AppReducer.State()) {
        AppReducer()
    })
}

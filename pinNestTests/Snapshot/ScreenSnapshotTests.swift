import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

/// 画面（フルスクリーン）のヴィジュアルリグレッションテスト。
///
/// `EmptyReducer` で Store を構築し、`onAppear` 等の effect を発火させず
/// 固定 State をそのまま描画する（依存の差し替え不要・非同期で State が変化しない）。
@MainActor
@Suite("Screen Snapshot")
struct ScreenSnapshotTests {
    @Test func settings() {
        // appVersion / buildNumber は通常 onAppear の effect で Bundle から設定されるが、
        // EmptyReducer では発火しないため代表値を明示してバージョン表示を再現する。
        var state = SettingsReducer.State(colorScheme: .system)
        state.appVersion = "1.1.1"
        state.buildNumber = "42"
        let store = Store(initialState: state) {
            EmptyReducer<SettingsReducer.State, SettingsReducer.Action>()
        }
        assertScreenSnapshotInBothColorSchemes(of: SettingsView(store: store), named: "settings")
    }

    @Test func pinList() {
        let store = Store(
            initialState: PinListReducer.State(pins: makeSnapshotPins())
        ) {
            EmptyReducer<PinListReducer.State, PinListReducer.Action>()
        }
        assertScreenSnapshotInBothColorSchemes(of: PinListView(store: store), named: "pinList")
    }

    @Test func history() {
        let store = Store(
            initialState: HistoryReducer.State(pins: makeSnapshotPins())
        ) {
            EmptyReducer<HistoryReducer.State, HistoryReducer.Action>()
        }
        assertScreenSnapshotInBothColorSchemes(of: HistoryView(store: store), named: "history")
    }

    @Test func pinDetail() {
        let pin = makeSnapshotPin(
            contentType: .url,
            title: "Apple（日本）",
            urlString: "https://www.apple.com/jp/",
            memo: "公式サイト。新製品情報をチェックする。"
        )
        let store = Store(
            initialState: PinDetailReducer.State(pin: pin)
        ) {
            EmptyReducer<PinDetailReducer.State, PinDetailReducer.Action>()
        }
        assertScreenSnapshotInBothColorSchemes(of: PinDetailView(store: store), named: "pinDetail")
    }
}

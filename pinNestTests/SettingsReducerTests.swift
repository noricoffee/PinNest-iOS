import ComposableArchitecture
import Foundation
import Testing

@Suite("SettingsReducer", .serialized)
@MainActor
struct SettingsReducerTests {

    // MARK: - onAppear

    @Test("onAppear でバージョン情報が設定される")
    func onAppear_setsVersionInfo() async {
        let store = TestStore(
            initialState: SettingsReducer.State(colorScheme: .system)
        ) {
            SettingsReducer()
        }

        // Bundle.main の値を先読みして expected state を組み立てる
        let expectedVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let expectedBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"

        await store.send(.onAppear) { state in
            state.appVersion = expectedVersion
            state.buildNumber = expectedBuild
        }
    }

    // MARK: - colorSchemeChanged

    @Test("colorSchemeChanged でテーマが変更される（dark）")
    func colorSchemeChanged_updatesToDark() async {
        let store = TestStore(
            initialState: SettingsReducer.State(colorScheme: .system)
        ) {
            SettingsReducer()
        }

        await store.send(.colorSchemeChanged(.dark)) { state in
            state.colorScheme = .dark
        }

        await store.finish()
    }

    @Test("colorSchemeChanged でテーマが変更される（light）")
    func colorSchemeChanged_updatesToLight() async {
        let store = TestStore(
            initialState: SettingsReducer.State(colorScheme: .dark)
        ) {
            SettingsReducer()
        }

        await store.send(.colorSchemeChanged(.light)) { state in
            state.colorScheme = .light
        }

        await store.finish()
    }

    @Test("colorSchemeChanged でテーマが変更される（system）")
    func colorSchemeChanged_updatesToSystem() async {
        let store = TestStore(
            initialState: SettingsReducer.State(colorScheme: .dark)
        ) {
            SettingsReducer()
        }

        await store.send(.colorSchemeChanged(.system)) { state in
            state.colorScheme = .system
        }

        await store.finish()
    }

    // MARK: - UserDefaults 保存

    @Test("colorSchemeChanged で UserDefaults に保存される")
    func colorSchemeChanged_savesToUserDefaults() async {
        // テスト前にキーを削除
        UserDefaults.standard.removeObject(forKey: "colorSchemePreference")

        let store = TestStore(
            initialState: SettingsReducer.State(colorScheme: .system)
        ) {
            SettingsReducer()
        }

        await store.send(.colorSchemeChanged(.dark)) { state in
            state.colorScheme = .dark
        }

        await store.finish()

        // UserDefaults に保存されたことを確認
        let savedValue = UserDefaults.standard.string(forKey: "colorSchemePreference")
        #expect(savedValue == ColorSchemePreference.dark.rawValue)

        // クリーンアップ
        UserDefaults.standard.removeObject(forKey: "colorSchemePreference")
    }

    // MARK: - doneButtonTapped

    @Test("doneButtonTapped は状態を変更しない")
    func doneButtonTapped_noStateChange() async {
        let store = TestStore(
            initialState: SettingsReducer.State(colorScheme: .light)
        ) {
            SettingsReducer()
        }

        await store.send(.doneButtonTapped)
    }

    // MARK: - ColorSchemePreference

    @Test("ColorSchemePreference.colorScheme の変換")
    func colorSchemePreference_colorSchemeConversion() {
        #expect(ColorSchemePreference.system.colorScheme == nil)
        #expect(ColorSchemePreference.light.colorScheme == .light)
        #expect(ColorSchemePreference.dark.colorScheme == .dark)
    }

    @Test("ColorSchemePreference.label の確認")
    func colorSchemePreference_labels() {
        #expect(ColorSchemePreference.system.label == "システム")
        #expect(ColorSchemePreference.light.label == "ライト")
        #expect(ColorSchemePreference.dark.label == "ダーク")
    }

    @Test("ColorSchemePreference rawValue")
    func colorSchemePreference_rawValues() {
        #expect(ColorSchemePreference.system.rawValue == "system")
        #expect(ColorSchemePreference.light.rawValue == "light")
        #expect(ColorSchemePreference.dark.rawValue == "dark")
    }

    @Test("ColorSchemePreference: 全ケースが CaseIterable に含まれる")
    func colorSchemePreference_allCases() {
        let allCases = ColorSchemePreference.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.system))
        #expect(allCases.contains(.light))
        #expect(allCases.contains(.dark))
    }
}

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsReducer>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                displaySection
                appInfoSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        store.send(.doneButtonTapped)
                    }
                    .accessibilityLabel("設定を閉じる")
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    // MARK: - 表示セクション

    private var displaySection: some View {
        Section("表示") {
            VStack(alignment: .leading, spacing: 12) {
                Text("テーマ")
                    .font(.body)
                Picker(
                    "テーマ",
                    selection: $store.colorScheme.sending(\.colorSchemeChanged)
                ) {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                        Text(preference.label).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("テーマ切り替え")
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - アプリ情報セクション

    private var appInfoSection: some View {
        Section("アプリ情報") {
            LabeledContent("バージョン", value: "\(store.appVersion) (\(store.buildNumber))")

            NavigationLink {
                LicenseView()
            } label: {
                Text("ライセンス")
            }
            .accessibilityLabel("ライセンス情報を表示")
        }
    }
}

// MARK: - LicenseView

private struct LicenseView: View {
    var body: some View {
        List {
            licenseRow(
                name: "The Composable Architecture",
                author: "Point-Free, Inc.",
                url: "https://github.com/pointfreeco/swift-composable-architecture",
                license: "MIT License"
            )
        }
        .navigationTitle("ライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func licenseRow(name: String, author: String, url: String, license: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.body)
                .foregroundStyle(.primary)
            Text(author)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(license)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(author), \(license)")
    }
}

// MARK: - Preview

#Preview {
    SettingsView(store: Store(initialState: SettingsReducer.State()) {
        SettingsReducer()
    })
}

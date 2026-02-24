import ComposableArchitecture
import SwiftUI

struct TagPickerView: View {
    @Bindable var store: StoreOf<TagPickerReducer>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // タグ新規作成セクション
                Section {
                    HStack(spacing: 12) {
                        TextField("タグ名を入力...", text: $store.newTagName.sending(\.newTagNameChanged))
                            .autocorrectionDisabled()
                            .accessibilityLabel("新規タグ名")
                        if store.isCreating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button("作成") {
                                store.send(.createTagButtonTapped)
                            }
                            .disabled(store.newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .foregroundStyle(Color.accentColor)
                            .fontWeight(.medium)
                        }
                    }
                }

                // 既存タグ一覧
                if !store.availableTags.isEmpty {
                    Section("既存のタグ") {
                        ForEach(store.availableTags) { tag in
                            Button {
                                store.send(.tagSelected(tag))
                            } label: {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .font(.footnote)
                                        .foregroundStyle(Color.accentColor)
                                    Text("#\(tag.name)")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityLabel("\(tag.name) を追加")
                        }
                    }
                } else if store.newTagName.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "タグがありません",
                            systemImage: "tag",
                            description: Text("上のフォームから新規タグを作成してください")
                        )
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("タグを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        store.send(.cancelButtonTapped)
                    }
                    .accessibilityLabel("キャンセル")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        store.send(.doneButtonTapped)
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("完了")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TagPickerView(store: Store(
        initialState: TagPickerReducer.State(
            pinId: UUID(),
            availableTags: [
                TagItem(id: UUID(), name: "swift"),
                TagItem(id: UUID(), name: "iOS"),
                TagItem(id: UUID(), name: "design"),
            ]
        )
    ) {
        TagPickerReducer()
    })
}

import SwiftUI

struct PinCreateView: View {
    @State private var selectedType: PinContentType
    @State private var urlText = ""
    @State private var bodyText = ""
    @State private var title = ""
    @State private var memo = ""
    @Environment(\.dismiss) private var dismiss

    init(contentType: PinContentType) {
        _selectedType = State(initialValue: contentType)
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    typeSelectorSection
                    Divider().padding(.vertical, 16)
                    contentInputSection
                    Divider().padding(.vertical, 16)
                    commonFieldsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .navigationTitle("ピンを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { dismiss() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Type Selector

    private var typeSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PinContentType.allCases) { type in
                    typeChip(type)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func typeChip(_ type: PinContentType) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedType = type }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.subheadline)
                Text(type.label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                in: Capsule()
            )
        }
        .accessibilityLabel("\(type.label)を選択")
        .animation(.easeInOut(duration: 0.2), value: selectedType)
    }

    // MARK: - Content Input

    @ViewBuilder
    private var contentInputSection: some View {
        switch selectedType {
        case .url:
            urlInputSection
        case .text:
            textInputSection
        case .image, .video, .pdf:
            filePickerSection
        }
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("URL")
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .foregroundStyle(.secondary)
                TextField("https://", text: $urlText)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !urlText.isEmpty {
                    Button {
                        urlText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("URL をクリア")
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("テキスト")
            TextEditor(text: $bodyText)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var filePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(selectedType.label)
            Button {
                // TODO: ファイル選択アクション（PhotosPicker / DocumentPicker）
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: selectedType.iconName)
                        .font(.system(size: 36))
                        .foregroundStyle(Color.accentColor)
                    Text("\(selectedType.label)を選択")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(
                    Color.accentColor.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                )
            }
            .accessibilityLabel("\(selectedType.label)を選択")
        }
    }

    // MARK: - Common Fields

    private var commonFieldsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // タイトル
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("タイトル")
                TextField("タイトルを入力", text: $title)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            // メモ
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    sectionLabel("メモ")
                    Text("任意")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextEditor(text: $memo)
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    PinCreateView(contentType: .url)
}

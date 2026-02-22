import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PinCreateView: View {
    @State private var selectedType: PinContentType
    @State private var urlText = ""
    @State private var bodyText = ""
    @State private var title = ""
    @State private var memo = ""

    // ファイル選択系
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedFileName: String?
    @State private var isFileImporterPresented = false

    @Environment(\.dismiss) private var dismiss

    init(contentType: PinContentType) {
        _selectedType = State(initialValue: contentType)
    }

    /// 保存時に実際に使用されるタイトル
    private var effectiveTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { return trimmed }
        switch selectedType {
        case .url:
            let url = urlText.trimmingCharacters(in: .whitespaces)
            return url.isEmpty ? currentDateTimeString : url
        case .text:
            let body = bodyText.trimmingCharacters(in: .whitespaces)
            return body.isEmpty ? currentDateTimeString : String(body.prefix(100))
        case .image, .video, .pdf:
            return currentDateTimeString
        }
    }

    private var currentDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: Date())
    }

    /// タイトル TextField のプレースホルダー
    private var titlePlaceholder: String {
        switch selectedType {
        case .url:   "任意（空欄時は URL をタイトルとして使用）"
        case .text:  "任意（空欄時は本文をタイトルとして使用）"
        case .image, .video, .pdf: "任意（空欄時は日時を設定）"
        }
    }

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
                        .fontWeight(.semibold)
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf]
            ) { result in
                if case .success(let url) = result {
                    selectedFileName = url.lastPathComponent
                }
            }
            .task(id: selectedPhotoItem) {
                guard let item = selectedPhotoItem else { return }
                if selectedType == .image {
                    selectedImage = try? await item.loadTransferable(type: Image.self)
                }
            }
            .onChange(of: selectedType) {
                selectedPhotoItem = nil
                selectedImage = nil
                selectedFileName = nil
            }
        }
    }

    // MARK: - Type Selector

    private var typeSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PinContentType.allCases, id: \.self) { type in
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

    @ViewBuilder
    private var filePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(selectedType.label)
            switch selectedType {
            case .image:
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    PickerPlaceholderView(icon: PinContentType.image.iconName, label: "画像を選択")
                }
                .accessibilityLabel("フォトライブラリから画像を選択")
                if let image = selectedImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("選択済みの画像プレビュー")
                }
            case .video:
                PhotosPicker(selection: $selectedPhotoItem, matching: .videos) {
                    PickerPlaceholderView(icon: PinContentType.video.iconName, label: "動画を選択")
                }
                .accessibilityLabel("フォトライブラリから動画を選択")
                if selectedPhotoItem != nil {
                    selectedItemRow(icon: "checkmark.circle.fill", name: "動画が選択されました")
                }
            case .pdf:
                Button { isFileImporterPresented = true } label: {
                    PickerPlaceholderView(icon: PinContentType.pdf.iconName, label: "PDFを選択")
                }
                .accessibilityLabel("ファイルから PDF を選択")
                if let name = selectedFileName {
                    selectedItemRow(icon: "doc.richtext.fill", name: name)
                }
            case .url, .text:
                EmptyView()
            }
        }
    }

    private func selectedItemRow(icon: String, name: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text(name)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("選択済み: \(name)")
    }

    // MARK: - Common Fields

    private var commonFieldsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("タイトル")
                TextField(titlePlaceholder, text: $title)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

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

// MARK: - PickerPlaceholderView
// PhotosPicker の label クロージャは PhotosUI 側が nonisolated 扱いのため、
// @MainActor メソッドを直接呼べない。独立した View struct にすることで解決する。

private struct PickerPlaceholderView: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
            Text(label)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color.accentColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6])
                )
        )
        .accessibilityHidden(true)
    }
}

#Preview {
    PinCreateView(contentType: .image)
}

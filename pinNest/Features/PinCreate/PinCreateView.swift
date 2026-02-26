import ComposableArchitecture
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct PinCreateView: View {
    @Bindable var store: StoreOf<PinCreateReducer>

    // 非 Sendable のため View の @State で管理
    @State private var selectedPhotoItem: PhotosPickerItem?
    // imageData は PhotosPickerItem 同様に View で保持する
    // .task からの store.send を避けることで "ifLet received a presentation action
    // when destination state was absent" 警告を防ぐ（Save 時のみ Reducer に渡す）
    @State private var loadedImageData: Data?
    // 動画: App Group へコピー済みの相対パス（Save 時に Reducer へ渡す）
    @State private var savedVideoPath: String?
    @State private var isFileImporterPresented = false
    @FocusState private var focusedField: FocusedField?

    private enum FocusedField { case url, body }

    /// loadedImageData から画像プレビューを生成（UIKit 依存のため View 側で変換）
    private var previewImage: Image? {
        guard let data = loadedImageData,
              let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
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
            .navigationTitle(store.mode == .create ? "ピンを作成" : "ピンを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        store.send(.cancelButtonTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.isSaving ? "保存中..." : "保存") {
                        store.send(.saveButtonTapped(imageData: loadedImageData, videoPath: savedVideoPath))
                    }
                    .fontWeight(.semibold)
                    .disabled(store.isSaving)
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf]
            ) { result in
                if case .success(let url) = result {
                    store.send(.fileNameSelected(url.lastPathComponent))
                }
            }
            .task(id: selectedPhotoItem) {
                guard let item = selectedPhotoItem else {
                    loadedImageData = nil
                    return
                }
                // FileRepresentation でファイル名を取得（Photos 権限不要）
                switch store.contentType {
                case .image:
                    if let f = try? await item.loadTransferable(type: ImageFileTransferable.self) {
                        store.send(.fileNameSelected(f.filename))
                    }
                    // store.send は行わず View の @State に格納するだけ
                    // → pinCreate が nil になった後に dispatch する競合状態を回避
                    loadedImageData = try? await item.loadTransferable(type: Data.self)
                case .video:
                    if let saved = try? await item.loadTransferable(type: VideoFileSaved.self) {
                        store.send(.fileNameSelected(saved.filename))
                        savedVideoPath = saved.relativePath
                    }
                default:
                    break
                }
            }
            .onChange(of: store.contentType) { _, newType in
                selectedPhotoItem = nil
                loadedImageData = nil
                savedVideoPath = nil
                focusedField = Self.focusedField(for: newType)
            }
            .onAppear {
                focusedField = Self.focusedField(for: store.contentType)
            }
        }
    }

    private static func focusedField(for type: ContentType) -> FocusedField? {
        switch type {
        case .url:  return .url
        case .text: return .body
        default:    return nil
        }
    }

    // MARK: - Type Selector

    private var typeSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    typeChip(type)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func typeChip(_ type: ContentType) -> some View {
        let isSelected = store.contentType == type
        return Button {
            store.send(.contentTypeChanged(type), animation: .easeInOut(duration: 0.2))
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
        .animation(.easeInOut(duration: 0.2), value: store.contentType)
    }

    // MARK: - Content Input

    @ViewBuilder
    private var contentInputSection: some View {
        switch store.contentType {
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
                TextField("https://", text: Binding(
                    get: { store.urlText },
                    set: { store.send(.urlTextChanged($0)) }
                ))
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .url)
                if !store.urlText.isEmpty {
                    Button {
                        store.send(.urlTextChanged(""))
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
            TextEditor(text: Binding(
                get: { store.bodyText },
                set: { store.send(.bodyTextChanged($0)) }
            ))
            .focused($focusedField, equals: .body)
            .frame(minHeight: 120)
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private var filePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(store.contentType.label)
            switch store.contentType {
            case .image:
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    PickerPlaceholderView(icon: ContentType.image.iconName, label: "画像を選択")
                }
                .accessibilityLabel("フォトライブラリから画像を選択")
                if let image = previewImage {
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
                    PickerPlaceholderView(icon: ContentType.video.iconName, label: "動画を選択")
                }
                .accessibilityLabel("フォトライブラリから動画を選択")
                if selectedPhotoItem != nil {
                    selectedItemRow(icon: "checkmark.circle.fill", name: store.selectedFileName ?? "動画が選択されました")
                }
            case .pdf:
                Button { isFileImporterPresented = true } label: {
                    PickerPlaceholderView(icon: ContentType.pdf.iconName, label: "PDFを選択")
                }
                .accessibilityLabel("ファイルから PDF を選択")
                if let name = store.selectedFileName {
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
                TextField(store.titlePlaceholder, text: Binding(
                    get: { store.title },
                    set: { store.send(.titleChanged($0)) }
                ))
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
                TextEditor(text: Binding(
                    get: { store.memo },
                    set: { store.send(.memoChanged($0)) }
                ))
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

// MARK: - FileTransferable helpers
// PhotosPickerItem から FileRepresentation 経由でファイル名を取得する。
// PHAsset / Photos 権限が不要なため権限ダイアログも出ない。

private struct ImageFileTransferable: Transferable {
    let filename: String
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            ImageFileTransferable(filename: received.file.lastPathComponent)
        }
    }
}

private struct VideoFileSaved: Transferable {
    let filename: String
    let relativePath: String?

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let ext = received.file.pathExtension
            let fileUUID = UUID()
            let dir: URL
            if let appGroupDir = AppGroupContainer.filesURL {
                dir = appGroupDir
            } else {
                let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                dir = base.appendingPathComponent("PinFiles", isDirectory: true)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let destURL = dir.appendingPathComponent("\(fileUUID.uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: destURL)
            let relativePath = ThumbnailCache.toRelativePath(destURL.path)
            return VideoFileSaved(
                filename: received.file.lastPathComponent,
                relativePath: relativePath
            )
        }
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
    PinCreateView(store: Store(
        initialState: PinCreateReducer.State(contentType: .image)
    ) {
        PinCreateReducer()
    })
}

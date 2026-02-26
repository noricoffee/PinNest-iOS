import ComposableArchitecture
import SwiftUI

// MARK: - ShareView

struct ShareView: View {
    let store: StoreOf<ShareReducer>
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("pinNest に保存")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            store.send(.cancelButtonTapped)
                        }
                        .accessibilityLabel("キャンセル")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if store.isSaving {
                            ProgressView()
                        } else {
                            Button("保存") {
                                store.send(.saveButtonTapped)
                            }
                            .fontWeight(.semibold)
                            .disabled(store.loadingState == .loading)
                            .accessibilityLabel("保存")
                        }
                    }
                }
        }
        .onChange(of: store.dismissRequest) { _, request in
            guard let request else { return }
            switch request {
            case .complete: onComplete()
            case .cancel: onCancel()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch store.loadingState {
        case .loading:
            loadingView
        case let .loaded(contentType, loadedContent):
            loadedView(contentType: contentType, content: loadedContent)
        case let .error(message):
            errorView(message: message)
        }
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("読み込み中...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("読み込み中")
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("エラー: \(message)")
    }

    // MARK: - Loaded State

    private func loadedView(contentType: ContentType, content: ShareReducer.State.LoadedContent) -> some View {
        Form {
            // コンテンツプレビュー
            Section {
                contentPreview(contentType: contentType, content: content)
                    .padding(.vertical, 8)
            }

            // タイトル・メモ入力
            Section("詳細") {
                TextField(
                    titlePlaceholder(for: contentType),
                    text: Binding(
                        get: { store.title },
                        set: { store.send(.titleChanged($0)) }
                    )
                )
                .accessibilityLabel("タイトル")

                TextField(
                    "メモ（任意）",
                    text: Binding(
                        get: { store.memo },
                        set: { store.send(.memoChanged($0)) }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...6)
                .accessibilityLabel("メモ")
            }

            // 保存エラー表示
            if let error = store.saveError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("エラー: \(error)")
            }
        }
    }

    // MARK: - Content Preview

    @ViewBuilder
    private func contentPreview(contentType: ContentType, content: ShareReducer.State.LoadedContent) -> some View {
        switch content {
        case let .url(urlString, thumbData):
            URLPreviewRow(urlString: urlString, thumbData: thumbData)

        case let .image(data):
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("画像プレビュー")
            }

        case let .video(_, filename):
            FilePreviewRow(
                iconName: "play.rectangle.fill",
                color: contentType.displayColor,
                filename: filename,
                typeName: "動画"
            )

        case let .pdf(_, filename):
            FilePreviewRow(
                iconName: "doc.richtext.fill",
                color: contentType.displayColor,
                filename: filename,
                typeName: "PDF"
            )

        case let .text(body):
            TextPreviewRow(body: body, color: contentType.displayColor)
        }
    }

    // MARK: - Helpers

    private func titlePlaceholder(for contentType: ContentType) -> String {
        switch contentType {
        case .url:             "タイトル（任意・OG タイトルがあれば自動入力）"
        case .text:            "タイトル（任意・本文から自動設定）"
        case .image, .video, .pdf: "タイトル（任意）"
        }
    }
}

// MARK: - URL Preview Row

private struct URLPreviewRow: View {
    let urlString: String
    let thumbData: Data?

    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            Group {
                if let thumbData, let image = UIImage(data: thumbData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color(.systemGray5)
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)

            // URL テキスト
            VStack(alignment: .leading, spacing: 4) {
                if let host = URL(string: urlString)?.host {
                    Text(host)
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(urlString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("URL: \(urlString)")
    }
}

// MARK: - File Preview Row

private struct FilePreviewRow: View {
    let iconName: String
    let color: Color
    let filename: String
    let typeName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(filename)
                    .font(.headline)
                    .lineLimit(2)
                Text(typeName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(typeName): \(filename)")
    }
}

// MARK: - Text Preview Row

private struct TextPreviewRow: View {
    let body: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text("テキスト")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(body)
                .font(.body)
                .lineLimit(6)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("テキスト: \(body)")
    }
}

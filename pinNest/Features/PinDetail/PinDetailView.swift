import AVKit
import ComposableArchitecture
import SwiftUI
import UIKit

struct PinDetailView: View {
    @Bindable var store: StoreOf<PinDetailReducer>
    @Environment(\.colorSchemePreference) private var colorSchemePreference
    @State private var isVideoPlayerPresented = false
    @State private var isImageViewerPresented = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerView
                    contentView
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    tagSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.tagSectionAppeared)
            }
            .sheet(item: $store.scope(state: \.tagPicker, action: \.tagPicker)) { pickerStore in
                TagPickerView(store: pickerStore)
                    .preferredColorScheme(colorSchemePreference.colorScheme)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.closeButtonTapped)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                    }
                    .accessibilityLabel("閉じる")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            store.send(.favoriteButtonTapped)
                        } label: {
                            Image(systemName: store.pin.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(store.pin.isFavorite ? .red : .primary)
                        }
                        .disabled(store.isFavoriteLoading)
                        .accessibilityLabel(store.pin.isFavorite ? "お気に入り解除" : "お気に入りに追加")

                        Button {
                            store.send(.editButtonTapped)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .accessibilityLabel("編集")

                        Button {
                            store.send(.deleteButtonTapped)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("削除")
                    }
                }
            }
            .alert(
                "ピンを削除しますか？",
                isPresented: Binding(
                    get: { store.isDeleteAlertPresented },
                    set: { if !$0 { store.send(.deleteAlertDismissed) } }
                )
            ) {
                Button("削除", role: .destructive) {
                    store.send(.deleteConfirmed)
                }
                Button("キャンセル", role: .cancel) {
                    store.send(.deleteAlertDismissed)
                }
            } message: {
                Text("この操作は取り消せません。")
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        switch store.pin.contentType {
        case .url:
            urlHeader
        case .image:
            imageHeader
        case .video:
            videoHeader
        case .pdf:
            pdfHeader
        case .text:
            EmptyView()
        }
    }

    @ViewBuilder
    private var urlHeader: some View {
        if let filePath = store.pin.filePath,
           let uiImage = UIImage(contentsOfFile: ThumbnailCache.resolveAbsolutePath(filePath)) {
            // Color.clear でアスペクト比フレームを確立し、Image を overlay で乗せる
            Color.clear
                .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityLabel("URL サムネイル")
        } else {
            store.pin.contentType.displayColor
                .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "globe")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(12)
                }
        }
    }

    @ViewBuilder
    private var imageHeader: some View {
        if let filePath = store.pin.filePath,
           let uiImage = UIImage(contentsOfFile: ThumbnailCache.resolveAbsolutePath(filePath)) {
            Button {
                isImageViewerPresented = true
            } label: {
                Color.clear
                    .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
            .accessibilityLabel("画像を拡大表示")
            .fullScreenCover(isPresented: $isImageViewerPresented) {
                ImageViewerView(uiImage: uiImage)
            }
        } else {
            store.pin.contentType.displayColor
                .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                }
        }
    }

    @ViewBuilder
    private var videoHeader: some View {
        if let filePath = store.pin.filePath {
            let absolutePath = ThumbnailCache.resolveAbsolutePath(filePath)
            let videoURL = URL(fileURLWithPath: absolutePath)
            let thumbnail = ThumbnailCache.loadThumbnail(for: store.pin.id)
            Button {
                isVideoPlayerPresented = true
            } label: {
                Group {
                    if let thumbnail {
                        Color.clear
                            .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                            }
                            .clipped()
                    } else {
                        store.pin.contentType.displayColor
                            .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    }
                }
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                }
            }
            .accessibilityLabel("動画を再生")
            .sheet(isPresented: $isVideoPlayerPresented) {
                AVPlayerViewControllerRepresentable(url: videoURL)
                    .ignoresSafeArea()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        } else {
            store.pin.contentType.displayColor
                .aspectRatio(store.pin.contentType.defaultAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                }
        }
    }

    @ViewBuilder
    private var pdfHeader: some View {
        let thumbnail = ThumbnailCache.loadThumbnail(for: store.pin.id)
        if let thumbnail {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                }
                .clipped()
                .background(Color(.tertiarySystemBackground))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(12)
                }
                .accessibilityLabel("PDF サムネイル")
        } else {
            HStack(spacing: 16) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(Color(.tertiarySystemBackground))
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch store.pin.contentType {
        case .url:
            urlContent
        case .image:
            imageContent
        case .video:
            videoContent
        case .pdf:
            pdfContent
        case .text:
            textContent
        }
    }

    private var urlContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaHeader

            Text(store.pin.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            if let urlString = store.pin.urlString,
               let host = URL(string: urlString)?.host() {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.footnote)
                    Text(host)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            }

            Button {
                store.send(.safariOpenTapped)
            } label: {
                HStack {
                    Text("Safari で開く")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.12))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Safari で開く")

            // メタデータ手動再取得ボタン
            Button {
                store.send(.refreshMetadataTapped)
            } label: {
                HStack(spacing: 8) {
                    if store.isRefreshingMetadata {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(store.isRefreshingMetadata ? "取得中..." : "サムネイルを再取得")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
            .disabled(store.isRefreshingMetadata)
            .accessibilityLabel("サムネイルを再取得")
        }
    }

    private var imageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaHeader
            Text(store.pin.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var videoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaHeader
            Text(store.pin.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pdfContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaHeader
            Text(store.pin.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaHeader

            Text(store.pin.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            if let body = store.pin.bodyText, !body.isEmpty {
                Text(body)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Shared

    private var metaHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.pin.createdAt, format: .dateTime.year().month().day().hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: store.pin.contentType.iconName)
                    .font(.caption2)
                Text(store.pin.contentType.label)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tag Section

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Text("タグ")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    store.send(.addTagButtonTapped)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("追加")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("タグを追加")
            }

            if store.pinTags.isEmpty {
                Text("タグなし")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.pinTags) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag.name)")
                                    .font(.subheadline)
                                Button {
                                    store.send(.tagRemoveTapped(tag))
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityLabel("\(tag.name) タグを削除")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground), in: Capsule())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ImageViewerView

private struct ImageViewerView: View {
    let uiImage: UIImage
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .opacity(1 - Double(max(dragOffset, 0)) / 300)
                .ignoresSafeArea()
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: max(dragOffset, 0))
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, .white.opacity(0.3))
                    .padding(16)
            }
            .accessibilityLabel("閉じる")
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    guard value.translation.height > 0 else { return }
                    state = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
}

// MARK: - AVPlayerViewControllerRepresentable

private struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.player?.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

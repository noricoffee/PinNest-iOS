import SwiftUI

struct PinDetailView: View {
    let item: PinPreviewItem
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerView
                    contentView
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                    }
                    .accessibilityLabel("閉じる")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: シェア
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("シェア")
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        switch item.contentType {
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

    private var urlHeader: some View {
        item.thumbnailColor
            .aspectRatio(item.thumbnailAspectRatio, contentMode: .fit)
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

    private var imageHeader: some View {
        item.thumbnailColor
            .aspectRatio(item.thumbnailAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "photo.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(10)
            }
    }

    private var videoHeader: some View {
        item.thumbnailColor
            .aspectRatio(item.thumbnailAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8)
            }
    }

    private var pdfHeader: some View {
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

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch item.contentType {
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

            Text(item.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = item.subtitle {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.footnote)
                    Text(subtitle)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            }

            Button {
                // TODO: Safari で開く
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
        }
    }

    private var imageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaHeader
            Text(item.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var videoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaHeader
            Text(item.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pdfContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaHeader
            Text(item.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            metaHeader

            Text(item.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            if let body = item.previewText {
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
            Text(item.addedAt, format: .dateTime.year().month().day().hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: item.contentType.iconName)
                    .font(.caption2)
                Text(item.contentType.label)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("URL") {
    PinDetailView(item: PinPreviewItem.samples[1])
}

#Preview("テキスト") {
    PinDetailView(item: PinPreviewItem.samples[2])
}

#Preview("画像") {
    PinDetailView(item: PinPreviewItem.samples[0])
}

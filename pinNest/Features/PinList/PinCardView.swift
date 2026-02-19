import SwiftUI

struct PinCardView: View {
    let item: PinPreviewItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailView
            infoView
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        switch item.contentType {
        case .url:
            urlThumbnail
        case .image:
            imageThumbnail
        case .video:
            videoThumbnail
        case .pdf:
            pdfThumbnail
        case .text:
            textPreview
        }
    }

    private var urlThumbnail: some View {
        item.thumbnailColor
            .aspectRatio(item.thumbnailAspectRatio, contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "globe")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(8)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 14
                )
            )
    }

    private var imageThumbnail: some View {
        item.thumbnailColor
            .aspectRatio(item.thumbnailAspectRatio, contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "photo.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(6)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 14
                )
            )
    }

    private var videoThumbnail: some View {
        item.thumbnailColor
            .aspectRatio(item.thumbnailAspectRatio, contentMode: .fit)
            .overlay {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 14
                )
            )
    }

    private var pdfThumbnail: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.richtext.fill")
                .font(.system(size: 38))
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(Color(.tertiarySystemBackground))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 14
            )
        )
    }

    private var textPreview: some View {
        Text(item.previewText ?? "")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .background(Color(.tertiarySystemBackground))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 14
                )
            )
    }

    // MARK: - Info

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let subtitle = item.subtitle {
                HStack(spacing: 3) {
                    Image(systemName: item.contentType.iconName)
                        .font(.caption2)
                    Text(subtitle)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }
}

#Preview {
    HStack(alignment: .top, spacing: 12) {
        VStack(spacing: 12) {
            PinCardView(item: PinPreviewItem.samples[0])
            PinCardView(item: PinPreviewItem.samples[2])
        }
        VStack(spacing: 12) {
            PinCardView(item: PinPreviewItem.samples[1])
            PinCardView(item: PinPreviewItem.samples[5])
        }
    }
    .padding()
    .background(Color(.systemBackground))
}

import SwiftUI
import UIKit

struct PinCardView: View {
    let pin: Pin

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
        switch pin.contentType {
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

    private var topRoundedShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 14,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 14
        )
    }

    @ViewBuilder
    private var urlThumbnail: some View {
        if let filePath = pin.filePath,
           let uiImage = UIImage(contentsOfFile: ThumbnailCache.resolveAbsolutePath(filePath)) {
            // Color.clear でアスペクト比フレームを確立し、Image を overlay で乗せる
            // （scaledToFill + frame(maxWidth:.infinity) + aspectRatio の組み合わせは
            //   SwiftUI レイアウトを混乱させるためこのパターンを使用）
            Color.clear
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .clipShape(topRoundedShape)
                .accessibilityLabel("URL サムネイル")
        } else {
            pin.contentType.displayColor
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "globe")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
                .clipShape(topRoundedShape)
        }
    }

    @ViewBuilder
    private var imageThumbnail: some View {
        if let filePath = pin.filePath,
           let uiImage = UIImage(contentsOfFile: ThumbnailCache.resolveAbsolutePath(filePath)) {
            Color.clear
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .clipShape(topRoundedShape)
                .accessibilityLabel("画像サムネイル")
        } else {
            pin.contentType.displayColor
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "photo.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(6)
                }
                .clipShape(topRoundedShape)
        }
    }

    @ViewBuilder
    private var videoThumbnail: some View {
        if let thumbnail = ThumbnailCache.loadThumbnail(for: pin.id) {
            Color.clear
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                }
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6)
                }
                .clipped()
                .clipShape(topRoundedShape)
                .accessibilityLabel("動画サムネイル")
        } else {
            pin.contentType.displayColor
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 6)
                }
                .clipShape(topRoundedShape)
        }
    }

    @ViewBuilder
    private var pdfThumbnail: some View {
        if let thumbnail = ThumbnailCache.loadThumbnail(for: pin.id) {
            Color.clear
                .aspectRatio(pin.contentType.defaultAspectRatio, contentMode: .fit)
                .overlay {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(5)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
                .clipped()
                .clipShape(topRoundedShape)
                .accessibilityLabel("PDF サムネイル")
        } else {
            HStack(spacing: 10) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.red)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color(.tertiarySystemBackground))
            .clipShape(topRoundedShape)
        }
    }

    private var textPreview: some View {
        Text(pin.bodyText ?? "")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .background(Color(.tertiarySystemBackground))
            .clipShape(topRoundedShape)
    }

    // MARK: - Info

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(pin.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundStyle(.primary)

            HStack(spacing: 3) {
                Image(systemName: pin.contentType.iconName)
                    .font(.caption2)
                if let urlString = pin.urlString,
                   let host = URL(string: urlString)?.host() {
                    Text(host)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }
}

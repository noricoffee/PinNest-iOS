@preconcurrency import LinkPresentation
import Dependencies
import Foundation
import UniformTypeIdentifiers

struct URLMetadata: Equatable, Sendable {
    var title: String?
    var thumbnailData: Data?
    var faviconData: Data?
}

struct MetadataClient: Sendable {
    var fetch: @Sendable (URL) async throws -> URLMetadata
}

extension MetadataClient: DependencyKey {
    static let liveValue = MetadataClient(
        fetch: { url in
            // LPMetadataProvider はコールバックベース → withCheckedThrowingContinuation でラップ
            let lpMetadata: LPLinkMetadata = try await withCheckedThrowingContinuation { continuation in
                let provider = LPMetadataProvider()
                provider.startFetchingMetadata(for: url) { metadata, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: metadata ?? LPLinkMetadata())
                    }
                }
            }

            var result = URLMetadata()
            result.title = lpMetadata.title

            // og:image をサムネイルとして取得
            if let imageProvider = lpMetadata.imageProvider {
                result.thumbnailData = await loadItemData(from: imageProvider)
            }

            // ファビコン取得
            if let iconProvider = lpMetadata.iconProvider {
                result.faviconData = await loadItemData(from: iconProvider)
            }

            return result
        }
    )

    static let testValue = MetadataClient(
        fetch: unimplemented("\(Self.self).fetch", placeholder: URLMetadata())
    )
}

/// NSItemProvider から画像データを非同期に読み込む
private func loadItemData(from provider: NSItemProvider) async -> Data? {
    await withCheckedContinuation { continuation in
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            continuation.resume(returning: data)
        }
    }
}

extension DependencyValues {
    var metadataClient: MetadataClient {
        get { self[MetadataClient.self] }
        set { self[MetadataClient.self] = newValue }
    }
}

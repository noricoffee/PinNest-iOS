@preconcurrency import LinkPresentation
import Dependencies
import Foundation
import os
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
            // タイムアウト（10秒）を Task.sleep で並走させ、先に完了した方で resume する
            let lpMetadata: LPLinkMetadata = try await withCheckedThrowingContinuation { continuation in
                let provider = LPMetadataProvider()
                // コールバックとタイムアウトの両方から resume される可能性があるため、
                // OSAllocatedUnfairLock で一度だけ resume することを保証する
                let lock = OSAllocatedUnfairLock(initialState: false)
                let timeoutTask = Task {
                    try await Task.sleep(for: .seconds(10))
                    let shouldResume = lock.withLock { alreadyResumed -> Bool in
                        guard !alreadyResumed else { return false }
                        alreadyResumed = true
                        return true
                    }
                    if shouldResume {
                        continuation.resume(throwing: URLError(.timedOut))
                    }
                }
                provider.startFetchingMetadata(for: url) { metadata, error in
                    timeoutTask.cancel()
                    let shouldResume = lock.withLock { alreadyResumed -> Bool in
                        guard !alreadyResumed else { return false }
                        alreadyResumed = true
                        return true
                    }
                    guard shouldResume else { return }
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
/// UIImage オブジェクトとして取得した後 JPEG 変換することで、
/// "public.image" 抽象型ではなく具体型（PNG/JPEG 等）のプロバイダーにも対応する
private func loadItemData(from provider: NSItemProvider) async -> Data? {
    // UIImage としてロードできる場合はそちらを優先（最も信頼性が高い）
    if provider.canLoadObject(ofClass: UIImage.self) {
        return await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    continuation.resume(returning: image.jpegData(compressionQuality: 0.7))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    // フォールバック: データとして直接ロード
    return await withCheckedContinuation { continuation in
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

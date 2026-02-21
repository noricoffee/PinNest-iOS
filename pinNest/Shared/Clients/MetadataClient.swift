import Dependencies
import Foundation

struct URLMetadata: Equatable, Sendable {
    var title: String?
    var thumbnailData: Data?
    var faviconData: Data?
}

struct MetadataClient: Sendable {
    var fetch: @Sendable (URL) async throws -> URLMetadata
}

extension MetadataClient: DependencyKey {
    // Phase 4 で LPMetadataProvider を使った実装に差し替える
    static let liveValue = MetadataClient(
        fetch: { _ in URLMetadata() }
    )

    static let testValue = MetadataClient(
        fetch: unimplemented("\(Self.self).fetch", placeholder: URLMetadata())
    )
}

extension DependencyValues {
    var metadataClient: MetadataClient {
        get { self[MetadataClient.self] }
        set { self[MetadataClient.self] = newValue }
    }
}

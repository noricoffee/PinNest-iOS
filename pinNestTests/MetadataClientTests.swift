import Foundation
import Testing

@Suite("MetadataClient")
@MainActor
struct MetadataClientTests {

    // MARK: - URLMetadata Equatable

    @Test("URLMetadata: 同じ値は等しい")
    func urlMetadata_equalityWithSameValues() {
        let data = Data([0x01, 0x02, 0x03])
        let a = URLMetadata(title: "Test", thumbnailData: data, faviconData: nil)
        let b = URLMetadata(title: "Test", thumbnailData: data, faviconData: nil)

        #expect(a == b)
    }

    @Test("URLMetadata: タイトルが異なると不等")
    func urlMetadata_inequalityWithDifferentTitle() {
        let a = URLMetadata(title: "Title A", thumbnailData: nil, faviconData: nil)
        let b = URLMetadata(title: "Title B", thumbnailData: nil, faviconData: nil)

        #expect(a != b)
    }

    @Test("URLMetadata: サムネイルが異なると不等")
    func urlMetadata_inequalityWithDifferentThumbnail() {
        let a = URLMetadata(title: "Same", thumbnailData: Data([0x01]), faviconData: nil)
        let b = URLMetadata(title: "Same", thumbnailData: Data([0x02]), faviconData: nil)

        #expect(a != b)
    }

    @Test("URLMetadata: デフォルト初期化は全フィールドが nil")
    func urlMetadata_defaultInit_allNil() {
        let metadata = URLMetadata()

        #expect(metadata.title == nil)
        #expect(metadata.thumbnailData == nil)
        #expect(metadata.faviconData == nil)
    }

    // MARK: - モック実装テスト

    @Test("モック MetadataClient: fetch が指定した URLMetadata を返す")
    func mockClient_fetch_returnsExpectedMetadata() async throws {
        let expectedURL = URL(string: "https://example.com")!
        let expectedMetadata = URLMetadata(
            title: "Example Domain",
            thumbnailData: Data([0xDE, 0xAD]),
            faviconData: Data([0xBE, 0xEF])
        )

        // @Sendable クロージャ内での var capture を避けるため参照型を使用
        final class Captured: @unchecked Sendable { var url: URL? }
        let captured = Captured()

        let client = MetadataClient { url in
            captured.url = url
            return expectedMetadata
        }

        let result = try await client.fetch(expectedURL)

        #expect(captured.url == expectedURL)
        #expect(result == expectedMetadata)
    }

    @Test("モック MetadataClient: fetch が throw したエラーを伝播する")
    func mockClient_fetch_propagatesError() async {
        struct NetworkError: Error {}

        let client = MetadataClient { _ in
            throw NetworkError()
        }

        await #expect(throws: NetworkError.self) {
            try await client.fetch(URL(string: "https://example.com")!)
        }
    }

    @Test("モック MetadataClient: タイトルのみの URLMetadata")
    func mockClient_fetch_titleOnly() async throws {
        let client = MetadataClient { _ in
            URLMetadata(title: "Page Title", thumbnailData: nil, faviconData: nil)
        }

        let result = try await client.fetch(URL(string: "https://example.com")!)

        #expect(result.title == "Page Title")
        #expect(result.thumbnailData == nil)
        #expect(result.faviconData == nil)
    }

    @Test("モック MetadataClient: 空の URLMetadata（フォールバック動作確認）")
    func mockClient_fetch_emptyMetadata() async throws {
        let client = MetadataClient { _ in URLMetadata() }

        let result = try await client.fetch(URL(string: "https://example.com")!)

        #expect(result == URLMetadata())
    }
}

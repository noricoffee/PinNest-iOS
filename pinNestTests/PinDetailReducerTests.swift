import ComposableArchitecture
import Foundation
import Testing

@Suite("PinDetailReducer - 要約")
@MainActor
struct PinDetailReducerSummaryTests {

    private func makePin(contentType: ContentType = .text, bodyText: String? = "本文テキスト") -> Pin {
        Pin(
            id: UUID(),
            contentType: contentType,
            title: "タイトル",
            bodyText: bodyText
        )
    }

    // MARK: - availability

    @Test("summarySectionAppeared で availability が反映される")
    func summarySectionAppeared_setsAvailability() async {
        let store = TestStore(
            initialState: PinDetailReducer.State(pin: makePin())
        ) {
            PinDetailReducer()
        } withDependencies: {
            $0.summarizationClient.availability = { .intelligenceNotEnabled }
        }

        await store.send(.summarySectionAppeared) { state in
            state.summarizeAvailability = .intelligenceNotEnabled
        }
    }

    // MARK: - 正常系

    @Test("要約成功で pin.summary が反映され updateSummary が呼ばれる")
    func summarize_success_updatesSummaryAndPersists() async {
        let pin = makePin(contentType: .text, bodyText: "要約対象の本文")

        final class Captured: @unchecked Sendable {
            var extractedType: ContentType?
            var summarizedSource: String?
            var savedId: UUID?
            var savedSummary: String?
        }
        let captured = Captured()

        let store = TestStore(
            initialState: PinDetailReducer.State(pin: pin)
        ) {
            PinDetailReducer()
        } withDependencies: {
            $0.contentExtractorClient.extract = { type, _, _, body in
                captured.extractedType = type
                return body ?? ""
            }
            $0.summarizationClient.summarize = { source in
                captured.summarizedSource = source
                return "これは要約です。"
            }
            $0.pinClient.updateSummary = { id, summary in
                captured.savedId = id
                captured.savedSummary = summary
            }
        }

        await store.send(.summarizeButtonTapped) { state in
            state.isSummarizing = true
        }

        await store.receive(\.summarizeResponse.success) { state in
            state.isSummarizing = false
            state.pin.summary = "これは要約です。"
        }

        #expect(captured.extractedType == .text)
        #expect(captured.summarizedSource == "要約対象の本文")
        #expect(captured.savedId == pin.id)
        #expect(captured.savedSummary == "これは要約です。")
    }

    // MARK: - 異常系

    @Test("要約失敗で isSummarizing が false に戻る")
    func summarize_failure_clearsSummarizing() async {
        struct SummarizeFailed: Error {}

        let store = TestStore(
            initialState: PinDetailReducer.State(pin: makePin())
        ) {
            PinDetailReducer()
        } withDependencies: {
            $0.contentExtractorClient.extract = { _, _, _, body in body ?? "" }
            $0.summarizationClient.summarize = { _ in throw SummarizeFailed() }
        }

        await store.send(.summarizeButtonTapped) { state in
            state.isSummarizing = true
        }

        await store.receive(\.summarizeResponse.failure) { state in
            state.isSummarizing = false
        }
    }

    // MARK: - ガード

    @Test("availability が非対応のときは summarizeButtonTapped を無視する")
    func summarize_ignored_whenUnavailable() async {
        var initial = PinDetailReducer.State(pin: makePin())
        initial.summarizeAvailability = .deviceNotEligible

        let store = TestStore(initialState: initial) {
            PinDetailReducer()
        }

        // 副作用なし・状態変化なし
        await store.send(.summarizeButtonTapped)
    }

    @Test("画像ピンでは summarizeButtonTapped を無視する")
    func summarize_ignored_forImage() async {
        let store = TestStore(
            initialState: PinDetailReducer.State(pin: makePin(contentType: .image, bodyText: nil))
        ) {
            PinDetailReducer()
        }

        await store.send(.summarizeButtonTapped)
    }

    @Test("要約中は summarizeButtonTapped を無視する")
    func summarize_ignored_whileSummarizing() async {
        var initial = PinDetailReducer.State(pin: makePin())
        initial.isSummarizing = true

        let store = TestStore(initialState: initial) {
            PinDetailReducer()
        }

        await store.send(.summarizeButtonTapped)
    }
}

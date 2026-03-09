import ComposableArchitecture
import Foundation

/// ピンの長押しコンテキストメニュー共通ロジック。
/// 各画面の Reducer が `Scope(state: \.contextMenu, action: \.contextMenu)` で合成する。
/// 削除完了・タグピッカー dismiss 後のリフレッシュは親 Reducer が
/// `.contextMenu(.deleteResponse(.success))` / `.contextMenu(.tagPicker(.dismiss))` を
/// インターセプトして行う。
@Reducer
struct PinContextMenuReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var pinToDelete: Pin? = nil
        var isDeleteAlertPresented: Bool = false
        var tagPinId: UUID? = nil
        @Presents var tagPicker: TagPickerReducer.State? = nil
        var shareItems: [String] = []
        var isShareSheetPresented: Bool = false

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.pinToDelete?.id == rhs.pinToDelete?.id &&
            lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
            lhs.tagPinId == rhs.tagPinId &&
            lhs.tagPicker == rhs.tagPicker &&
            lhs.shareItems == rhs.shareItems &&
            lhs.isShareSheetPresented == rhs.isShareSheetPresented
        }
    }

    // MARK: - Action

    enum Action {
        case deleteTapped(Pin)
        case deleteAlertDismissed
        case deleteConfirmed
        case deleteResponse(Result<Void, Error>)
        case addTagTapped(Pin)
        case tagsLoaded(Result<([TagItem], [TagItem]), Error>)
        case tagPicker(PresentationAction<TagPickerReducer.Action>)
        case openLinkTapped(Pin)
        case copyLinkTapped(Pin)
        case copyBodyTapped(Pin)
        case shareTapped(Pin)
        case shareSheetDismissed
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
            @Dependency(\.analyticsClient) var analyticsClient
            @Dependency(\.crashlyticsClient) var crashlyticsClient
            @Dependency(\.hapticClient) var hapticClient
            @Dependency(\.openURL) var openURL
            @Dependency(\.pasteboardClient) var pasteboardClient
            switch action {

            case let .deleteTapped(pin):
                state.pinToDelete = pin
                state.isDeleteAlertPresented = true
                return .none

            case .deleteAlertDismissed:
                state.isDeleteAlertPresented = false
                state.pinToDelete = nil
                return .none

            case .deleteConfirmed:
                guard let pin = state.pinToDelete else { return .none }
                state.isDeleteAlertPresented = false
                hapticClient.notification(.warning)
                let id = pin.id
                state.pinToDelete = nil
                return .run { send in
                    await send(.deleteResponse(Result {
                        try await pinClient.delete(id)
                    }))
                }

            case .deleteResponse(.success):
                analyticsClient.logEvent(.pinDeleted)
                // リフレッシュは親 Reducer がインターセプトして行う
                return .none

            case let .deleteResponse(.failure(error)):
                crashlyticsClient.recordError(error, "PinClient.delete.contextMenu")
                return .none

            case let .addTagTapped(pin):
                let pinId = pin.id
                state.tagPinId = pinId
                return .run { send in
                    await send(.tagsLoaded(Result {
                        let pinTags = try await pinClient.fetchTagsForPin(pinId)
                        let allTags = try await pinClient.fetchAllTags()
                        return (pinTags, allTags)
                    }))
                }

            case let .tagsLoaded(.success((pinTags, allTags))):
                guard let pinId = state.tagPinId else { return .none }
                let currentTagIds = Set(pinTags.map(\.id))
                let availableTags = allTags.filter { !currentTagIds.contains($0.id) }
                state.tagPicker = TagPickerReducer.State(pinId: pinId, availableTags: availableTags)
                return .none

            case .tagsLoaded(.failure):
                return .none

            case .tagPicker(.dismiss):
                // リフレッシュは親 Reducer がインターセプトして行う
                return .none

            case .tagPicker:
                return .none

            case let .openLinkTapped(pin):
                guard let urlString = pin.urlString,
                      let url = URL(string: urlString) else { return .none }
                analyticsClient.logEvent(.urlOpened)
                return .run { _ in
                    await openURL(url)
                }

            case let .copyLinkTapped(pin):
                guard let urlString = pin.urlString else { return .none }
                pasteboardClient.copy(urlString)
                hapticClient.notification(.success)
                return .none

            case let .copyBodyTapped(pin):
                guard let bodyText = pin.bodyText else { return .none }
                pasteboardClient.copy(bodyText)
                hapticClient.notification(.success)
                return .none

            case let .shareTapped(pin):
                switch pin.contentType {
                case .url:
                    state.shareItems = [pin.urlString ?? pin.title]
                case .text:
                    state.shareItems = [pin.bodyText ?? pin.title]
                case .image, .video, .pdf:
                    state.shareItems = [pin.title]
                }
                state.isShareSheetPresented = true
                return .none

            case .shareSheetDismissed:
                state.isShareSheetPresented = false
                state.shareItems = []
                return .none
            }
        }
        .ifLet(\.$tagPicker, action: \.tagPicker) {
            TagPickerReducer()
        }
    }
}

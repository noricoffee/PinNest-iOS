import ComposableArchitecture
import Foundation

@Reducer
struct PinDetailReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var pin: Pin
        var isDeleteAlertPresented: Bool = false
        var isFavoriteLoading: Bool = false
        var isRefreshingMetadata: Bool = false
        /// 削除処理中フラグ。true になった後は pin プロパティにアクセスしない
        var isBeingDeleted: Bool = false
        var pinTags: [TagItem] = []
        var allTags: [TagItem] = []
        @Presents var tagPicker: TagPickerReducer.State? = nil

        static func == (lhs: State, rhs: State) -> Bool {
            // 削除処理中は pin プロパティへのアクセスをスキップ
            guard !lhs.isBeingDeleted, !rhs.isBeingDeleted else {
                return lhs.isBeingDeleted == rhs.isBeingDeleted
            }
            return lhs.pin.id == rhs.pin.id &&
            lhs.pin.isFavorite == rhs.pin.isFavorite &&
            lhs.pin.filePath == rhs.pin.filePath &&
            lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
            lhs.isFavoriteLoading == rhs.isFavoriteLoading &&
            lhs.isRefreshingMetadata == rhs.isRefreshingMetadata &&
            lhs.pinTags == rhs.pinTags &&
            lhs.allTags == rhs.allTags &&
            lhs.tagPicker == rhs.tagPicker
        }
    }

    // MARK: - Action

    enum Action {
        // 既存
        case closeButtonTapped
        case favoriteButtonTapped
        case favoriteResponse(Result<Void, Error>)
        case deleteButtonTapped
        case deleteAlertDismissed
        case deleteConfirmed
        case deleteResponse(Result<Void, Error>)
        case editButtonTapped
        case safariOpenTapped
        case refreshMetadataTapped
        case metadataRefreshResponse(Result<String?, Error>)
        // タグ管理
        case tagSectionAppeared
        case tagsLoaded(Result<([TagItem], [TagItem]), Error>)
        case addTagButtonTapped
        case tagPicker(PresentationAction<TagPickerReducer.Action>)
        case tagRemoveTapped(TagItem)
        case tagRemoveResponse(Result<[TagItem], Error>)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.pinClient) var pinClient
            @Dependency(\.metadataClient) var metadataClient
            @Dependency(\.openURL) var openURL
            @Dependency(\.dismiss) var dismiss
            @Dependency(\.analyticsClient) var analyticsClient
            @Dependency(\.crashlyticsClient) var crashlyticsClient
            switch action {

            case .closeButtonTapped:
                return .run { _ in await dismiss() }

            case .favoriteButtonTapped:
                state.isFavoriteLoading = true
                state.pin.isFavorite.toggle()
                let id = state.pin.id
                let title = state.pin.title
                let memo = state.pin.memo
                let isFavorite = state.pin.isFavorite
                let urlString = state.pin.urlString
                let filePath = state.pin.filePath
                let bodyText = state.pin.bodyText
                return .run { send in
                    await send(.favoriteResponse(Result {
                        try await pinClient.update(id, title, memo, isFavorite, urlString, filePath, bodyText)
                    }))
                }

            case .favoriteResponse(.success):
                state.isFavoriteLoading = false
                analyticsClient.logEvent(.pinFavoriteToggled(isFavorite: state.pin.isFavorite))
                return .none

            case let .favoriteResponse(.failure(error)):
                state.isFavoriteLoading = false
                state.pin.isFavorite.toggle()
                crashlyticsClient.recordError(error, "PinClient.update.favorite")
                return .none

            case .deleteButtonTapped:
                state.isDeleteAlertPresented = true
                return .none

            case .deleteAlertDismissed:
                state.isDeleteAlertPresented = false
                return .none

            case .deleteConfirmed:
                // 同期処理でフラグを立て、View が pin プロパティにアクセスしないようにする。
                // deleteResponse が届くまでの間に SwiftData の変更通知で View が再描画されても安全。
                state.isBeingDeleted = true
                let id = state.pin.id
                return .run { send in
                    await send(.deleteResponse(Result {
                        try await pinClient.delete(id)
                    }))
                }

            case .deleteResponse(.success):
                analyticsClient.logEvent(.pinDeleted)
                // SwiftData が Pin を detach する前に即座に dismiss する。
                // dismiss を遅らせると View が再描画時に pin.contentType 等にアクセスしクラッシュする。
                return .run { _ in await dismiss() }

            case let .deleteResponse(.failure(error)):
                crashlyticsClient.recordError(error, "PinClient.delete")
                return .none

            case .editButtonTapped:
                return .none

            case .safariOpenTapped:
                guard let urlString = state.pin.urlString,
                      let url = URL(string: urlString) else { return .none }
                analyticsClient.logEvent(.urlOpened)
                return .run { _ in
                    await openURL(url)
                }

            case .refreshMetadataTapped:
                analyticsClient.logEvent(.metadataRefreshed)
                guard !state.isRefreshingMetadata,
                      state.pin.contentType == .url,
                      let urlString = state.pin.urlString,
                      let url = URL(string: urlString) else { return .none }
                state.isRefreshingMetadata = true
                let pinID = state.pin.id
                let oldFilePath = state.pin.filePath
                return .run { send in
                    do {
                        let metadata = try await metadataClient.fetch(url)
                        var newFilePath = oldFilePath
                        if let imageData = metadata.thumbnailData ?? metadata.faviconData {
                            if let old = oldFilePath { ThumbnailCache.remove(path: old) }
                            newFilePath = try ThumbnailCache.save(data: imageData, for: pinID)
                        }
                        await send(.metadataRefreshResponse(.success(newFilePath)))
                    } catch {
                        await send(.metadataRefreshResponse(.failure(error)))
                    }
                }

            case let .metadataRefreshResponse(.success(newPath)):
                state.isRefreshingMetadata = false
                state.pin.filePath = newPath
                let id = state.pin.id
                let title = state.pin.title
                let memo = state.pin.memo
                let isFavorite = state.pin.isFavorite
                let urlString = state.pin.urlString
                let bodyText = state.pin.bodyText
                return .run { _ in
                    try? await pinClient.update(id, title, memo, isFavorite, urlString, newPath, bodyText)
                }

            case let .metadataRefreshResponse(.failure(error)):
                state.isRefreshingMetadata = false
                crashlyticsClient.recordError(error, "MetadataClient.fetch")
                return .none

            // MARK: - Tag actions

            case .tagSectionAppeared:
                analyticsClient.logEvent(.pinViewed(contentType: state.pin.contentType.rawValue))
                let pinId = state.pin.id
                return .run { send in
                    await send(.tagsLoaded(Result {
                        let pinTags = try await pinClient.fetchTagsForPin(pinId)
                        let allTags = try await pinClient.fetchAllTags()
                        return (pinTags, allTags)
                    }))
                }

            case let .tagsLoaded(.success((pinTags, allTags))):
                state.pinTags = pinTags
                state.allTags = allTags
                return .none

            case .tagsLoaded(.failure):
                return .none

            case .addTagButtonTapped:
                let pinId = state.pin.id
                let currentTagIds = Set(state.pinTags.map(\.id))
                let availableTags = state.allTags.filter { !currentTagIds.contains($0.id) }
                state.tagPicker = TagPickerReducer.State(pinId: pinId, availableTags: availableTags)
                return .none

            case .tagPicker(.presented(.tagAddResponse(.success(let updatedPinTags)))):
                state.pinTags = updatedPinTags
                return .none

            case .tagPicker(.dismiss):
                // タグ追加後に allTags を最新化する（新規作成タグを反映）
                let pinId = state.pin.id
                return .run { send in
                    await send(.tagsLoaded(Result {
                        let pinTags = try await pinClient.fetchTagsForPin(pinId)
                        let allTags = try await pinClient.fetchAllTags()
                        return (pinTags, allTags)
                    }))
                }

            case .tagPicker:
                return .none

            case let .tagRemoveTapped(tag):
                let pinId = state.pin.id
                let tagId = tag.id
                return .run { send in
                    await send(.tagRemoveResponse(Result {
                        try await pinClient.removeTagFromPin(tagId, pinId)
                        return try await pinClient.fetchTagsForPin(pinId)
                    }))
                }

            case let .tagRemoveResponse(.success(updatedPinTags)):
                state.pinTags = updatedPinTags
                analyticsClient.logEvent(.tagRemoved)
                return .none

            case let .tagRemoveResponse(.failure(error)):
                crashlyticsClient.recordError(error, "PinClient.removeTagFromPin")
                return .none
            }
        }
        .ifLet(\.$tagPicker, action: \.tagPicker) {
            TagPickerReducer()
        }
    }
}

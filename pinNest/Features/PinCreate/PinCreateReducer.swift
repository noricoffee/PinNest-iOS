import ComposableArchitecture
import Foundation

@Reducer
struct PinCreateReducer {

    // MARK: - Mode

    enum Mode: Equatable {
        case create
        case edit(Pin)

        static func == (lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.create, .create): true
            case let (.edit(l), .edit(r)): l.id == r.id
            default: false
            }
        }
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var mode: Mode
        var contentType: ContentType

        var title: String = ""
        var memo: String = ""
        var urlText: String = ""
        var bodyText: String = ""
        var selectedFileName: String? = nil

        var isSaving: Bool = false
        var saveError: String? = nil

        /// 保存時に使用される実効タイトル
        var effectiveTitle: String {
            let trimmed = title.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { return trimmed }
            switch contentType {
            case .url:
                let url = urlText.trimmingCharacters(in: .whitespaces)
                return url.isEmpty ? currentDateTimeString : url
            case .text:
                let body = bodyText.trimmingCharacters(in: .whitespaces)
                return body.isEmpty ? currentDateTimeString : String(body.prefix(100))
            case .image, .video, .pdf:
                return currentDateTimeString
            }
        }

        /// タイトル入力欄のプレースホルダー
        var titlePlaceholder: String {
            switch contentType {
            case .url:   "任意（空欄時は OG タイトルまたは URL を使用）"
            case .text:  "任意（空欄時は本文をタイトルとして使用）"
            case .image, .video, .pdf: "任意（空欄時は日時を設定）"
            }
        }

        private var currentDateTimeString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter.string(from: Date())
        }

        init(mode: Mode = .create, contentType: ContentType) {
            self.mode = mode
            self.contentType = contentType

            if case let .edit(pin) = mode {
                self.title = pin.title
                self.memo = pin.memo
                self.urlText = pin.urlString ?? ""
                self.bodyText = pin.bodyText ?? ""
                self.contentType = pin.contentType
            }
        }
    }

    // MARK: - Action

    enum Action {
        case contentTypeChanged(ContentType)
        case titleChanged(String)
        case memoChanged(String)
        case urlTextChanged(String)
        case bodyTextChanged(String)
        case fileNameSelected(String?)
        case saveButtonTapped
        case saveResponse(Result<Void, Error>)
        case cancelButtonTapped
    }

    // MARK: - Reducer

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        @Dependency(\.pinClient) var pinClient
        @Dependency(\.metadataClient) var metadataClient
        @Dependency(\.analyticsClient) var analyticsClient
        @Dependency(\.crashlyticsClient) var crashlyticsClient
        switch action {

        case let .contentTypeChanged(type):
            state.contentType = type
            state.selectedFileName = nil
            return .none

        case let .titleChanged(text):
            state.title = text
            return .none

        case let .memoChanged(text):
            state.memo = text
            return .none

        case let .urlTextChanged(text):
            state.urlText = text
            return .none

        case let .bodyTextChanged(text):
            state.bodyText = text
            return .none

        case let .fileNameSelected(name):
            state.selectedFileName = name
            return .none

        case .saveButtonTapped:
            guard !state.isSaving else { return .none }
            state.isSaving = true
            state.saveError = nil

            let contentType = state.contentType
            let titleInput = state.effectiveTitle
            let memo = state.memo
            let urlString = contentType == .url ? state.urlText.trimmingCharacters(in: .whitespaces) : nil
            let bodyText = contentType == .text ? state.bodyText : nil

            switch state.mode {
            case .create:
                // URL ピン: メタデータ取得 → サムネイルキャッシュ → create
                if contentType == .url,
                   let urlString,
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    return .run { send in
                        // メタデータ取得（失敗してもサムネイルなしで続行）
                        let metadata = (try? await metadataClient.fetch(url)) ?? URLMetadata()

                        // サムネイル保存（og:image 優先、なければ favicon）
                        let pinID = UUID()
                        var thumbnailPath: String? = nil
                        if let imageData = metadata.thumbnailData ?? metadata.faviconData {
                            thumbnailPath = try? ThumbnailCache.save(data: imageData, for: pinID)
                        }

                        // og:title があればユーザー入力タイトルより優先（ユーザーが入力していない場合のみ）
                        let ogTitle = metadata.title?.trimmingCharacters(in: .whitespaces)
                        let finalTitle = (ogTitle?.isEmpty == false) ? ogTitle! : titleInput

                        let newPin = NewPin(
                            id: pinID,
                            contentType: contentType,
                            title: finalTitle,
                            memo: memo,
                            urlString: urlString,
                            filePath: thumbnailPath
                        )
                        await send(.saveResponse(Result {
                            try await pinClient.create(newPin)
                        }))
                    }
                }

                // URL 以外（または URL が空/不正）は直接 create
                let newPin = NewPin(
                    contentType: contentType,
                    title: titleInput,
                    memo: memo,
                    urlString: urlString,
                    bodyText: bodyText
                )
                return .run { send in
                    await send(.saveResponse(Result {
                        try await pinClient.create(newPin)
                    }))
                }

            case let .edit(existing):
                let id = existing.id
                let isFavorite = existing.isFavorite
                let filePath = existing.filePath
                return .run { send in
                    await send(.saveResponse(Result {
                        try await pinClient.update(id, titleInput, memo, isFavorite, urlString, filePath, bodyText)
                    }))
                }
            }

        case .saveResponse(.success):
            state.isSaving = false
            switch state.mode {
            case .create:
                analyticsClient.logEvent(.pinCreated(contentType: state.contentType.rawValue))
            case .edit:
                analyticsClient.logEvent(.pinEdited(contentType: state.contentType.rawValue))
            }
            // 親 (AppReducer) がシートを閉じてリストを更新する
            return .none

        case let .saveResponse(.failure(error)):
            state.isSaving = false
            state.saveError = error.localizedDescription
            let context: String
            switch state.mode {
            case .create: context = "PinClient.create"
            case .edit:   context = "PinClient.update"
            }
            crashlyticsClient.recordError(error, context)
            return .none

        case .cancelButtonTapped:
            // 親 (AppReducer) がシートを閉じる
            return .none
        }
    }
}

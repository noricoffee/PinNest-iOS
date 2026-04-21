import AVFoundation
import ComposableArchitecture
import Foundation
import PDFKit
import UIKit

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
                return selectedFileName ?? currentDateTimeString
            }
        }

        /// タイトル入力欄のプレースホルダー
        var titlePlaceholder: String {
            switch contentType {
            case .url:   "任意（空欄時は OG タイトルまたは URL を使用）"
            case .text:  "任意（空欄時は本文をタイトルとして使用）"
            case .image, .video, .pdf: "任意（空欄時はファイル名を使用）"
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
        /// View で非同期ロードされた画像データ・動画パス・PDF データを Save 時に受け取る
        /// （PhotosPickerItem は非 Sendable のため View の @State で管理し、Save 時のみ渡す）
        case saveButtonTapped(imageData: Data?, videoPath: String?, pdfData: Data?)
        case saveResponse(Result<Void, Error>)
        case cancelButtonTapped
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.analyticsClient) var analyticsClient
            @Dependency(\.crashlyticsClient) var crashlyticsClient
            @Dependency(\.hapticClient) var hapticClient
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

            case let .saveButtonTapped(imageData: imageData, videoPath: videoPath, pdfData: pdfData):
                guard !state.isSaving else { return .none }
                state.isSaving = true
                state.saveError = nil
                switch state.mode {
                case .create:
                    return Self.createEffect(state: state, imageData: imageData, videoPath: videoPath, pdfData: pdfData)
                case let .edit(existing):
                    return Self.editEffect(existing: existing, state: state)
                }

            case .saveResponse(.success):
                state.isSaving = false
                hapticClient.notification(.success)
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
                hapticClient.notification(.error)
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

    // MARK: - Private Effect Factories

    private static func createEffect(
        state: State,
        imageData: Data?,
        videoPath: String?,
        pdfData: Data?
    ) -> Effect<Action> {
        let contentType = state.contentType
        let titleInput = state.effectiveTitle
        let userTitle = state.title.trimmingCharacters(in: .whitespaces)
        let memo = state.memo
        let urlString = contentType == .url ? state.urlText.trimmingCharacters(in: .whitespaces) : nil
        let bodyText = contentType == .text ? state.bodyText : nil

        switch contentType {
        case .url:
            return createURLPin(urlString: urlString, userTitle: userTitle, titleInput: titleInput, memo: memo)
        case .image:
            return createImagePin(imageData: imageData, titleInput: titleInput, memo: memo)
        case .video:
            return createVideoPin(videoPath: videoPath, titleInput: titleInput, memo: memo)
        case .pdf:
            return createPDFPin(pdfData: pdfData, titleInput: titleInput, memo: memo)
        case .text:
            return createTextPin(contentType: contentType, titleInput: titleInput, memo: memo, urlString: urlString, bodyText: bodyText)
        }
    }

    private static func createURLPin(
        urlString: String?,
        userTitle: String,
        titleInput: String,
        memo: String
    ) -> Effect<Action> {
        guard let urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            // URL が無効な場合はテキストピンとして保存
            return createTextPin(contentType: .url, titleInput: titleInput, memo: memo, urlString: urlString, bodyText: nil)
        }
        return .run { send in
            @Dependency(\.metadataClient) var metadataClient
            @Dependency(\.pinClient) var pinClient
            // メタデータ取得（失敗してもサムネイルなしで続行）
            let metadata = (try? await metadataClient.fetch(url)) ?? URLMetadata()
            let pinID = UUID()
            var thumbnailPath: String? = nil
            if let data = metadata.thumbnailData ?? metadata.faviconData {
                thumbnailPath = try? ThumbnailCache.save(data: data, for: pinID)
            }
            // og:title はユーザーがタイトル未入力の場合のみ使用する
            let ogTitle = metadata.title?.trimmingCharacters(in: .whitespaces)
            let finalTitle = (!userTitle.isEmpty) ? titleInput : (ogTitle?.isEmpty == false ? ogTitle! : titleInput)
            let newPin = NewPin(id: pinID, contentType: .url, title: finalTitle, memo: memo, urlString: urlString, filePath: thumbnailPath)
            await send(.saveResponse(Result { try await pinClient.create(newPin) }))
        }
    }

    private static func createImagePin(imageData: Data?, titleInput: String, memo: String) -> Effect<Action> {
        let pinID = UUID()
        return .run { send in
            @Dependency(\.pinClient) var pinClient
            let filePath = imageData.flatMap { saveImageFile(data: $0, pinID: pinID) }
            let newPin = NewPin(id: pinID, contentType: .image, title: titleInput, memo: memo, filePath: filePath)
            await send(.saveResponse(Result { try await pinClient.create(newPin) }))
        }
    }

    private static func createVideoPin(videoPath: String?, titleInput: String, memo: String) -> Effect<Action> {
        let pinID = UUID()
        return .run { send in
            @Dependency(\.pinClient) var pinClient
            // 動画の最初のフレームをサムネイルとして保存
            if let videoPath, !videoPath.isEmpty {
                let videoURL = URL(fileURLWithPath: ThumbnailCache.resolveAbsolutePath(videoPath))
                if let thumbData = await generateVideoThumbnailData(videoURL: videoURL) {
                    _ = try? ThumbnailCache.save(data: thumbData, for: pinID)
                }
            }
            let newPin = NewPin(id: pinID, contentType: .video, title: titleInput, memo: memo, filePath: videoPath)
            await send(.saveResponse(Result { try await pinClient.create(newPin) }))
        }
    }

    private static func createPDFPin(pdfData: Data?, titleInput: String, memo: String) -> Effect<Action> {
        let pinID = UUID()
        return .run { send in
            @Dependency(\.pinClient) var pinClient
            let savedFilePath = pdfData.flatMap { savePDFFile(data: $0, pinID: pinID) }
            if let data = pdfData, let thumbData = generatePDFThumbnailData(pdfData: data) {
                _ = try? ThumbnailCache.save(data: thumbData, for: pinID)
            }
            let newPin = NewPin(id: pinID, contentType: .pdf, title: titleInput, memo: memo, filePath: savedFilePath)
            await send(.saveResponse(Result { try await pinClient.create(newPin) }))
        }
    }

    private static func createTextPin(
        contentType: ContentType,
        titleInput: String,
        memo: String,
        urlString: String?,
        bodyText: String?
    ) -> Effect<Action> {
        let newPin = NewPin(contentType: contentType, title: titleInput, memo: memo, urlString: urlString, bodyText: bodyText)
        return .run { send in
            @Dependency(\.pinClient) var pinClient
            await send(.saveResponse(Result { try await pinClient.create(newPin) }))
        }
    }

    private static func editEffect(existing: Pin, state: State) -> Effect<Action> {
        let id = existing.id
        let isFavorite = existing.isFavorite
        let filePath = existing.filePath
        let titleInput = state.effectiveTitle
        let memo = state.memo
        let contentType = state.contentType
        let urlString = contentType == .url ? state.urlText.trimmingCharacters(in: .whitespaces) : nil
        let bodyText = contentType == .text ? state.bodyText : nil
        return .run { send in
            @Dependency(\.pinClient) var pinClient
            await send(.saveResponse(Result {
                try await pinClient.update(id, titleInput, memo, isFavorite, urlString, filePath, bodyText)
            }))
        }
    }

    // MARK: - Private Helpers

    /// 動画の最初のフレームを JPEG データとして生成する
    private static func generateVideoThumbnailData(videoURL: URL) async -> Data? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 800)
        guard let cgImage = try? await generator.image(at: .zero).image else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.85)
    }

    /// PDF の最初のページを JPEG データとして生成する
    private static func generatePDFThumbnailData(pdfData: Data) -> Data? {
        guard let document = PDFDocument(data: pdfData),
              let firstPage = document.page(at: 0) else { return nil }
        let thumbSize = CGSize(width: 600, height: 800)
        let thumbnail = firstPage.thumbnail(of: thumbSize, for: .mediaBox)
        return thumbnail.jpegData(compressionQuality: 0.85)
    }

    /// PDF データをアプリコンテナ（App Group 優先）に保存し、相対パスを返す
    private static func savePDFFile(data: Data, pinID: UUID) -> String? {
        let dir: URL
        if let filesDir = AppGroupContainer.filesURL {
            dir = filesDir
        } else {
            guard let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let d = base.appendingPathComponent("PinFiles", isDirectory: true)
            try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
            dir = d
        }
        let fileURL = dir.appendingPathComponent("\(pinID.uuidString).pdf")
        do {
            try data.write(to: fileURL, options: .atomic)
            return ThumbnailCache.toRelativePath(fileURL.path)
        } catch {
            return nil
        }
    }

    /// 画像データをアプリコンテナ（App Group 優先）に JPEG で保存し、絶対パスを返す
    private static func saveImageFile(data: Data, pinID: UUID) -> String? {
        let dir: URL
        if let filesDir = AppGroupContainer.filesURL {
            dir = filesDir
        } else {
            guard let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let d = base.appendingPathComponent("PinFiles", isDirectory: true)
            try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
            dir = d
        }
        let fileURL = dir.appendingPathComponent("\(pinID.uuidString).jpg")
        let jpegData: Data
        if let uiImage = UIImage(data: data),
           let compressed = uiImage.jpegData(compressionQuality: 0.85) {
            jpegData = compressed
        } else {
            jpegData = data
        }
        do {
            try jpegData.write(to: fileURL, options: .atomic)
            // ビルド・再インストール時にコンテナ UUID が変わっても読み込めるよう相対パスで保存
            return ThumbnailCache.toRelativePath(fileURL.path)
        } catch {
            return nil
        }
    }
}

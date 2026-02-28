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

        case let .saveButtonTapped(imageData: imageData, videoPath: videoPath, pdfData: pdfData):
            guard !state.isSaving else { return .none }
            state.isSaving = true
            state.saveError = nil

            let contentType = state.contentType
            let titleInput = state.effectiveTitle
            let userTitle = state.title.trimmingCharacters(in: .whitespaces)
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

                        // og:title はユーザーがタイトル未入力の場合のみ使用する
                        let ogTitle = metadata.title?.trimmingCharacters(in: .whitespaces)
                        let finalTitle = (!userTitle.isEmpty) ? titleInput : (ogTitle?.isEmpty == false ? ogTitle! : titleInput)

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

                // 画像: ディスクに保存してから create
                if contentType == .image {
                    let pinID = UUID()
                    return .run { send in
                        let filePath = imageData.flatMap { Self.saveImageFile(data: $0, pinID: pinID) }
                        let newPin = NewPin(
                            id: pinID,
                            contentType: contentType,
                            title: titleInput,
                            memo: memo,
                            filePath: filePath
                        )
                        await send(.saveResponse(Result {
                            try await pinClient.create(newPin)
                        }))
                    }
                }

                // 動画: サムネイル生成 → filePath として記録
                if contentType == .video {
                    let pinID = UUID()
                    return .run { send in
                        // 動画の最初のフレームをサムネイルとして保存
                        if let videoPath, !videoPath.isEmpty {
                            let absolutePath = ThumbnailCache.resolveAbsolutePath(videoPath)
                            let videoURL = URL(fileURLWithPath: absolutePath)
                            if let thumbData = await Self.generateVideoThumbnailData(videoURL: videoURL) {
                                _ = try? ThumbnailCache.save(data: thumbData, for: pinID)
                            }
                        }
                        let newPin = NewPin(
                            id: pinID,
                            contentType: .video,
                            title: titleInput,
                            memo: memo,
                            filePath: videoPath
                        )
                        await send(.saveResponse(Result {
                            try await pinClient.create(newPin)
                        }))
                    }
                }

                // PDF: ファイル保存 + サムネイル生成
                if contentType == .pdf {
                    let pinID = UUID()
                    return .run { send in
                        let savedFilePath = pdfData.flatMap { Self.savePDFFile(data: $0, pinID: pinID) }
                        if let data = pdfData,
                           let thumbData = Self.generatePDFThumbnailData(pdfData: data) {
                            _ = try? ThumbnailCache.save(data: thumbData, for: pinID)
                        }
                        let newPin = NewPin(
                            id: pinID,
                            contentType: .pdf,
                            title: titleInput,
                            memo: memo,
                            filePath: savedFilePath
                        )
                        await send(.saveResponse(Result {
                            try await pinClient.create(newPin)
                        }))
                    }
                }

                // テキストは直接 create
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

import ComposableArchitecture
import Foundation
import UIKit
import UniformTypeIdentifiers

// MARK: - ShareReducer

@Reducer
struct ShareReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var loadingState: LoadingState = .loading
        var title: String = ""
        var memo: String = ""
        var isSaving: Bool = false
        var saveError: String? = nil
        var dismissRequest: DismissRequest? = nil

        /// NSItemProvider からロード済みのコンテンツ
        enum LoadingState: Equatable {
            case loading
            case loaded(ContentType, LoadedContent)
            case error(String)
        }

        enum LoadedContent: Equatable {
            case url(String, Data?)       // urlString, thumbnailData（メタデータ取得後に設定）
            case image(Data)              // imageData
            case video(URL, String)       // tempURL, filename
            case pdf(URL, String)         // tempURL, filename
            case text(String)             // bodyText
        }

        enum DismissRequest: Equatable {
            case complete
            case cancel
        }
    }

    // MARK: - Action

    enum Action {
        case loadContent([NSItemProvider])
        case contentLoaded(ContentType, State.LoadedContent)
        case metadataFetched(URLMetadata, urlString: String)
        case loadFailed(String)
        case titleChanged(String)
        case memoChanged(String)
        case saveButtonTapped
        case saveResponse(Result<Void, any Error>)
        case cancelButtonTapped
    }

    // MARK: - Reducer

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        @Dependency(\.pinClient) var pinClient
        @Dependency(\.metadataClient) var metadataClient

        switch action {

        case let .loadContent(providers):
            return .run { send in
                if let (contentType, content) = await loadFromProviders(providers) {
                    await send(.contentLoaded(contentType, content))
                } else {
                    await send(.loadFailed("対応していないコンテンツ形式です"))
                }
            }

        case let .contentLoaded(contentType, content):
            state.loadingState = .loaded(contentType, content)
            // URL の場合はメタデータ取得を追加実行
            if case let .url(urlString, _) = content {
                return .run { send in
                    if let url = URL(string: urlString),
                       let metadata = try? await metadataClient.fetch(url) {
                        await send(.metadataFetched(metadata, urlString: urlString))
                    }
                }
            }
            return .none

        case let .metadataFetched(metadata, urlString):
            guard case let .loaded(contentType, _) = state.loadingState else { return .none }
            let thumbData = metadata.thumbnailData ?? metadata.faviconData
            state.loadingState = .loaded(contentType, .url(urlString, thumbData))
            // OG タイトルがあり、ユーザーがタイトル未入力の場合にセット
            if state.title.isEmpty,
               let ogTitle = metadata.title?.trimmingCharacters(in: .whitespaces),
               !ogTitle.isEmpty {
                state.title = ogTitle
            }
            return .none

        case let .loadFailed(message):
            state.loadingState = .error(message)
            return .none

        case let .titleChanged(text):
            state.title = text
            return .none

        case let .memoChanged(text):
            state.memo = text
            return .none

        case .saveButtonTapped:
            guard !state.isSaving,
                  case let .loaded(contentType, loadedContent) = state.loadingState else {
                return .none
            }
            state.isSaving = true
            state.saveError = nil
            let title = effectiveTitle(state: state)
            let memo = state.memo

            return .run { send in
                await send(.saveResponse(Result {
                    try await savePin(
                        contentType: contentType,
                        loadedContent: loadedContent,
                        title: title,
                        memo: memo,
                        pinClient: pinClient
                    )
                }))
            }

        case .saveResponse(.success):
            state.isSaving = false
            state.dismissRequest = .complete
            return .none

        case let .saveResponse(.failure(error)):
            state.isSaving = false
            state.saveError = error.localizedDescription
            return .none

        case .cancelButtonTapped:
            state.dismissRequest = .cancel
            return .none
        }
    }
}

// MARK: - タイトル生成

private func effectiveTitle(state: ShareReducer.State) -> String {
    let trimmed = state.title.trimmingCharacters(in: .whitespaces)
    if !trimmed.isEmpty { return trimmed }

    if case let .loaded(contentType, content) = state.loadingState {
        switch contentType {
        case .url:
            if case let .url(urlString, _) = content { return urlString }
        case .text:
            if case let .text(body) = content {
                let trimmedBody = body.trimmingCharacters(in: .whitespaces)
                if !trimmedBody.isEmpty { return String(trimmedBody.prefix(100)) }
            }
        case .image, .video, .pdf:
            break
        }
    }
    return currentDateTimeString()
}

private func currentDateTimeString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter.string(from: Date())
}

// MARK: - NSItemProvider ロード

/// extensionContext の providers からコンテンツを読み込む
private func loadFromProviders(_ providers: [NSItemProvider]) async -> (ContentType, ShareReducer.State.LoadedContent)? {
    for provider in providers {
        // URL（http/https のみ）
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = await loadURL(from: provider),
               url.scheme == "http" || url.scheme == "https" {
                return (.url, .url(url.absoluteString, nil))
            }
        }
        // 画像
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let data = await loadImageData(from: provider) {
                return (.image, .image(data))
            }
        }
        // 動画
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            if let (tempURL, filename) = await loadTempFile(from: provider, typeID: UTType.movie.identifier) {
                return (.video, .video(tempURL, filename))
            }
        }
        // PDF
        if provider.hasItemConformingToTypeIdentifier("com.adobe.pdf") {
            if let (tempURL, filename) = await loadTempFile(from: provider, typeID: "com.adobe.pdf") {
                return (.pdf, .pdf(tempURL, filename))
            }
        }
        // テキスト
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = await loadText(from: provider) {
                return (.text, .text(text))
            }
        }
    }
    return nil
}

private func loadURL(from provider: NSItemProvider) async -> URL? {
    await withCheckedContinuation { continuation in
        provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
            if let url = item as? URL {
                continuation.resume(returning: url)
            } else if let data = item as? Data {
                continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}

private func loadImageData(from provider: NSItemProvider) async -> Data? {
    await withCheckedContinuation { continuation in
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            continuation.resume(returning: data)
        }
    }
}

/// ファイルを一時ディレクトリにコピーして URL を返す
/// （loadFileRepresentation のコールバック内 URL はクロージャ外で無効になるため）
private func loadTempFile(from provider: NSItemProvider, typeID: String) async -> (URL, String)? {
    await withCheckedContinuation { continuation in
        provider.loadFileRepresentation(forTypeIdentifier: typeID) { url, _ in
            guard let url else {
                continuation.resume(returning: nil)
                return
            }
            let filename = url.lastPathComponent
            let ext = url.pathExtension
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                continuation.resume(returning: (tempURL, filename))
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

private func loadText(from provider: NSItemProvider) async -> String? {
    await withCheckedContinuation { continuation in
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, _ in
            if let text = item as? String {
                continuation.resume(returning: text)
            } else if let data = item as? Data {
                continuation.resume(returning: String(data: data, encoding: .utf8))
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}

// MARK: - SwiftData 保存

private func savePin(
    contentType: ContentType,
    loadedContent: ShareReducer.State.LoadedContent,
    title: String,
    memo: String,
    pinClient: PinClient
) async throws {
    let pinID = UUID()

    switch loadedContent {
    case let .url(urlString, thumbData):
        var filePath: String? = nil
        if let thumbData {
            filePath = try? ThumbnailCache.save(data: thumbData, for: pinID)
        }
        let newPin = NewPin(
            id: pinID, contentType: .url,
            title: title, memo: memo,
            urlString: urlString, filePath: filePath
        )
        try await pinClient.create(newPin)

    case let .image(data):
        let filePath = try saveImageToAppGroup(data: data, pinID: pinID)
        let newPin = NewPin(
            id: pinID, contentType: .image,
            title: title, memo: memo,
            filePath: filePath
        )
        try await pinClient.create(newPin)

    case let .video(tempURL, _):
        let filePath = try copyFileToAppGroup(from: tempURL, pinID: pinID)
        let newPin = NewPin(
            id: pinID, contentType: .video,
            title: title, memo: memo,
            filePath: filePath
        )
        try await pinClient.create(newPin)
        try? FileManager.default.removeItem(at: tempURL)

    case let .pdf(tempURL, _):
        let filePath = try copyFileToAppGroup(from: tempURL, pinID: pinID)
        let newPin = NewPin(
            id: pinID, contentType: .pdf,
            title: title, memo: memo,
            filePath: filePath
        )
        try await pinClient.create(newPin)
        try? FileManager.default.removeItem(at: tempURL)

    case let .text(bodyText):
        let newPin = NewPin(
            id: pinID, contentType: .text,
            title: title, memo: memo,
            bodyText: bodyText
        )
        try await pinClient.create(newPin)
    }
}

private func saveImageToAppGroup(data: Data, pinID: UUID) throws -> String {
    guard let filesDir = AppGroupContainer.filesURL else {
        throw ShareExtensionError.appGroupUnavailable
    }
    let destURL = filesDir.appendingPathComponent("\(pinID.uuidString).jpg")
    if let image = UIImage(data: data), let jpegData = image.jpegData(compressionQuality: 0.9) {
        try jpegData.write(to: destURL, options: .atomic)
    } else {
        try data.write(to: destURL, options: .atomic)
    }
    return destURL.path
}

private func copyFileToAppGroup(from tempURL: URL, pinID: UUID) throws -> String {
    guard let filesDir = AppGroupContainer.filesURL else {
        throw ShareExtensionError.appGroupUnavailable
    }
    let ext = tempURL.pathExtension
    let destURL = filesDir.appendingPathComponent("\(pinID.uuidString).\(ext)")
    try FileManager.default.copyItem(at: tempURL, to: destURL)
    return destURL.path
}

// MARK: - Error

enum ShareExtensionError: LocalizedError {
    case appGroupUnavailable
    case noContent

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable: "App Group コンテナにアクセスできません"
        case .noContent: "コンテンツが見つかりませんでした"
        }
    }
}

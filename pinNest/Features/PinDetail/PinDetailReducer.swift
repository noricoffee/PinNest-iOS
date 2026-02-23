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

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.pin.id == rhs.pin.id &&
            lhs.pin.isFavorite == rhs.pin.isFavorite &&
            lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
            lhs.isFavoriteLoading == rhs.isFavoriteLoading
        }
    }

    // MARK: - Action

    enum Action {
        case favoriteButtonTapped
        case favoriteResponse(Result<Void, Error>)
        case deleteButtonTapped
        case deleteAlertDismissed
        case deleteConfirmed
        case deleteResponse(Result<Void, Error>)
        case editButtonTapped
        case safariOpenTapped
    }

    // MARK: - Reducer

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        @Dependency(\.pinClient) var pinClient
        @Dependency(\.openURL) var openURL
        switch action {

        case .favoriteButtonTapped:
            state.isFavoriteLoading = true
            state.pin.isFavorite.toggle()
            // value type として Pin の属性をコピーし actor 境界を越える
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
            return .none

        case .favoriteResponse(.failure):
            state.isFavoriteLoading = false
            // ロールバック
            state.pin.isFavorite.toggle()
            return .none

        case .deleteButtonTapped:
            state.isDeleteAlertPresented = true
            return .none

        case .deleteAlertDismissed:
            state.isDeleteAlertPresented = false
            return .none

        case .deleteConfirmed:
            let id = state.pin.id
            return .run { send in
                await send(.deleteResponse(Result {
                    try await pinClient.delete(id)
                }))
            }

        case .deleteResponse:
            // 親 (PinListReducer) がシートを閉じてリストを更新する
            return .none

        case .editButtonTapped:
            // 親 (AppReducer) が PinCreateReducer のシートを開く
            return .none

        case .safariOpenTapped:
            guard let urlString = state.pin.urlString,
                  let url = URL(string: urlString) else { return .none }
            return .run { _ in
                await openURL(url)
            }
        }
    }
}

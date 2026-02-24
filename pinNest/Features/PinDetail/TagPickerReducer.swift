import ComposableArchitecture
import Foundation

@Reducer
struct TagPickerReducer {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var pinId: UUID
        var newTagName: String = ""
        /// ピンにまだ付与されていないタグのみを格納する
        var availableTags: [TagItem]
        var isCreating: Bool = false
    }

    // MARK: - Action

    enum Action {
        case newTagNameChanged(String)
        case createTagButtonTapped
        case createTagResponse(Result<TagItem, Error>)
        case tagSelected(TagItem)
        /// 親 (PinDetailReducer) がキャッチして pinTags を更新する
        case tagAddResponse(Result<[TagItem], Error>)
        case cancelButtonTapped
        case doneButtonTapped
    }

    // MARK: - Reducer

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        @Dependency(\.pinClient) var pinClient
        @Dependency(\.dismiss) var dismiss
        @Dependency(\.analyticsClient) var analyticsClient
        switch action {

        case let .newTagNameChanged(name):
            state.newTagName = name
            return .none

        case .createTagButtonTapped:
            let name = state.newTagName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !state.isCreating else { return .none }
            state.isCreating = true
            return .run { send in
                await send(.createTagResponse(Result {
                    try await pinClient.createTag(name)
                }))
            }

        case let .createTagResponse(.success(newTag)):
            state.isCreating = false
            state.newTagName = ""
            analyticsClient.logEvent(.tagCreated)
            let pinId = state.pinId
            return .run { send in
                await send(.tagAddResponse(Result {
                    try await pinClient.addTagToPin(newTag.id, pinId)
                    return try await pinClient.fetchTagsForPin(pinId)
                }))
            }

        case .createTagResponse(.failure):
            state.isCreating = false
            return .none

        case let .tagSelected(tag):
            let pinId = state.pinId
            return .run { send in
                await send(.tagAddResponse(Result {
                    try await pinClient.addTagToPin(tag.id, pinId)
                    return try await pinClient.fetchTagsForPin(pinId)
                }))
            }

        case let .tagAddResponse(.success(updatedPinTags)):
            // 付与済みになったタグを availableTags から除外する
            let pinTagIds = Set(updatedPinTags.map(\.id))
            state.availableTags = state.availableTags.filter { !pinTagIds.contains($0.id) }
            analyticsClient.logEvent(.tagAssigned)
            return .none

        case .tagAddResponse(.failure):
            return .none

        case .cancelButtonTapped:
            return .run { _ in await dismiss() }

        case .doneButtonTapped:
            return .run { _ in await dismiss() }
        }
    }
}

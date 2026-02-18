# pinNest コーディング規約

## 概要

本ドキュメントは pinNest プロジェクトにおける Swift / SwiftUI / TCA のコーディング規約を定めます。
一貫したコードスタイルを維持し、可読性・保守性・テスタビリティを高めることを目的とします。

---

## 命名規則

### 基本方針

Swift の [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) に従います。

| 対象 | 規則 | 例 |
|------|------|----|
| 型（`struct` / `class` / `enum` / `protocol`） | UpperCamelCase | `PinItem`, `FeatureAReducer` |
| 関数・メソッド・変数・プロパティ | lowerCamelCase | `fetchItems()`, `isLoading` |
| 定数 | lowerCamelCase | `let maxCount = 100` |
| 列挙値 | lowerCamelCase | `case onAppear`, `case itemTapped` |

### TCA 固有の命名

| 要素 | 規則 | 例 |
|------|------|----|
| Reducer | `<機能名>Reducer` | `PinListReducer`, `SettingsReducer` |
| View | `<機能名>View` | `PinListView`, `SettingsView` |
| `State` | Reducer 内にネストした `State` | `PinListReducer.State` |
| `Action` | Reducer 内にネストした `Action` | `PinListReducer.Action` |
| `Action` の case | 動詞 + 目的語、またはイベント名 | `.fetchButtonTapped`, `.itemsResponse` |
| Effect 結果の Action | `<処理名>Response` | `.fetchItemsResponse` |

---

## ファイル構成

### 1 ファイル = 1 型を基本とする

```
// Good
// PinItem.swift
struct PinItem { ... }

// Bad
// Models.swift
struct PinItem { ... }
struct TagItem { ... }
```

### Reducer ファイルの構造

`@Reducer` 内は以下の順序で記述します。

```swift
@Reducer
struct FeatureAReducer {

    // 1. State
    @ObservableState
    struct State: Equatable { ... }

    // 2. Action
    enum Action { ... }

    // 3. Dependencies
    @Dependency(\.apiClient) var apiClient

    // 4. body
    var body: some ReducerOf<Self> { ... }
}
```

### View ファイルの構造

```swift
struct FeatureAView: View {

    // 1. Store
    @Bindable var store: StoreOf<FeatureAReducer>

    // 2. body
    var body: some View { ... }

    // 3. サブビュー（private）
    private var loadingOverlay: some View { ... }
}
```

---

## TCA コーディング規約

### State

- `struct` で定義し、`Equatable` に準拠する
- 画面に表示・操作する状態のみを持つ（導出可能な値は `var` プロパティで計算する）
- ネストした機能の State は `@Presents` または子 Reducer の State として保持する

```swift
// Good
@ObservableState
struct State: Equatable {
    var items: [PinItem] = []
    var isLoading: Bool = false

    var isEmpty: Bool { items.isEmpty }  // 導出値
}

// Bad: 導出可能な値を State に持たせない
struct State: Equatable {
    var items: [PinItem] = []
    var isEmpty: Bool = true  // items から導出できる
}
```

### Action

- ユーザー操作: `<UI要素><動詞>` 形式（例: `addButtonTapped`, `itemSwiped`）
- ライフサイクル: `onAppear`, `onDisappear`
- Effect 結果: `<処理名>Response(Result<T, Error>)` 形式

```swift
enum Action {
    // ユーザー操作
    case onAppear
    case addButtonTapped
    case itemTapped(PinItem)

    // Effect 結果
    case fetchItemsResponse(Result<[PinItem], Error>)
}
```

### Reducer

- `switch` の全 case を網羅し、`default` は使用しない
- 早期 `return .none` で副作用なしを明示する
- 複雑なロジックは private メソッドに切り出さず、Reducer 内に記述する（テスタビリティのため）

```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .onAppear:
            state.isLoading = true
            return .run { send in
                await send(.fetchItemsResponse(
                    Result { try await apiClient.fetchItems() }
                ))
            }

        case let .fetchItemsResponse(.success(items)):
            state.isLoading = false
            state.items = items
            return .none

        case .fetchItemsResponse(.failure):
            state.isLoading = false
            return .none

        case .addButtonTapped:
            return .none

        case .itemTapped:
            return .none
        }
    }
}
```

### Effect

- 非同期処理は `.run { send in ... }` を使用する
- キャンセル可能な Effect には `.cancellable(id:)` を付与する
- 副作用のない case は必ず `return .none` で終わらせる

```swift
// キャンセル可能な Effect
case .searchQueryChanged(let query):
    return .run { send in
        await send(.searchResponse(Result { try await apiClient.search(query) }))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
```

---

## SwiftUI 規約

### View の責務

- View はレイアウトと `store.send(...)` の呼び出しのみを担う
- ビジネスロジックを View に書かない

```swift
// Good
Button("追加") {
    store.send(.addButtonTapped)
}

// Bad: View にロジックを書かない
Button("追加") {
    if store.items.count < 100 {
        store.send(.addButtonTapped)
    }
}
```

### プレビュー

各 View にはプレビューを実装します。

```swift
#Preview {
    FeatureAView(
        store: Store(initialState: FeatureAReducer.State()) {
            FeatureAReducer()
        }
    )
}
```

---

## テスト規約

- テストファイルは `<対象型名>Tests.swift` とする
- `@Suite` と `@Test` を使用する（XCTestCase は使用しない）
- `TestStore` を用いて State の変化を逐一検証する
- `await store.receive(...)` で Effect が返す Action を検証する

```swift
@Suite("PinListReducer")
struct PinListReducerTests {

    @Test("onAppear でアイテムが取得される")
    func fetchItemsOnAppear() async {
        let mockItems = [PinItem(id: 1, title: "テスト")]

        let store = TestStore(initialState: PinListReducer.State()) {
            PinListReducer()
        } withDependencies: {
            $0.apiClient.fetchItems = { mockItems }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchItemsResponse(.success(mockItems))) {
            $0.isLoading = false
            $0.items = mockItems
        }
    }
}
```

---

## コメント

- コードを読めば分かることはコメントしない
- **なぜ**そうしているかを補足する場合にコメントを書く
- TODO / FIXME は課題管理と紐づける形で記述する

```swift
// Good: 理由を説明している
// API の仕様上、空配列が返された場合はエラーとして扱う
if items.isEmpty { throw APIError.emptyResponse }

// Bad: コードを言い換えているだけ
// items が空かどうかチェックする
if items.isEmpty { throw APIError.emptyResponse }
```

---

## 参考リンク

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [The Composable Architecture — GitHub](https://github.com/pointfreeco/swift-composable-architecture)
- [アーキテクチャ方針](./architecture.md)

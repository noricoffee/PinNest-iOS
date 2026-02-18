# pinNest アーキテクチャ

## 概要

pinNest は **The Composable Architecture（TCA）** を採用しています。  
TCA は [Point-Free](https://github.com/pointfreeco/swift-composable-architecture) が開発した SwiftUI 向けのアーキテクチャフレームワークであり、単方向データフロー・テスタビリティ・モジュール分割を軸に設計されています。

---

## 基本原則

| 原則 | 説明 |
|------|------|
| **単方向データフロー** | State → View → Action → Reducer → State の一方向サイクルで状態変化を管理する |
| **不変 State** | アプリの状態は単一の値型（`struct`）で表現し、副作用は `Effect` に隔離する |
| **テスタビリティ** | `TestStore` を用いてビジネスロジックを副作用込みでテストできる |
| **コンポーザビリティ** | 小さな `Reducer` を `Scope` / `.forEach` などで合成し、機能を段階的に組み立てる |

---

## TCA の構成要素

```
┌─────────────────────────────────┐
│             View                │  ← SwiftUI View
│  observe { store.someState }    │
└────────────┬────────────────────┘
             │ send(.someAction)
             ▼
┌─────────────────────────────────┐
│            Store                │  ← 状態保持・Reducer 実行・Effect 管理
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│           Reducer               │  ← 純粋関数: (State, Action) → Effect
│  @Reducer struct FeatureReducer │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│           Effect                │  ← 非同期処理・副作用 (Swift Concurrency)
└─────────────────────────────────┘
```

### 各要素の役割

| 要素 | 役割 |
|------|------|
| `State` | 画面や機能の状態を保持する値型（`struct`） |
| `Action` | ユーザー操作・システムイベント・Effect の結果を表す `enum` |
| `Reducer` | `State` と `Action` を受け取り、新しい `State` と `Effect` を返す純粋関数 |
| `Effect` | 非同期処理・API 通信・通知などの副作用。完了後に `Action` を返す |
| `Store` | `State` を保持し、`Action` を受け取って `Reducer` を実行するランタイム |

---

## ディレクトリ構成

```
pinNest/
├── App/
│   ├── pinNestApp.swift          # @main エントリポイント、ルート Store の生成
│   └── AppReducer.swift          # アプリ全体のルート Reducer
│
├── Features/                     # 機能単位のモジュール群
│   ├── FeatureA/
│   │   ├── FeatureAView.swift    # SwiftUI View
│   │   └── FeatureAReducer.swift # @Reducer（State / Action / body を含む）
│   └── FeatureB/
│       ├── FeatureBView.swift
│       └── FeatureBReducer.swift
│
├── Shared/                       # 複数 Feature で共有するコード
│   ├── Models/                   # ドメインモデル（値型中心）
│   ├── APIClient/                # DI 可能な API クライアント（TCA Dependency）
│   └── Extensions/
│
└── architecture.md               # 本ドキュメント
```

---

## Reducer の実装例

```swift
import ComposableArchitecture

@Reducer
struct FeatureAReducer {

    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var items: [Item] = []
        var isLoading: Bool = false
    }

    // MARK: - Action
    enum Action {
        case onAppear
        case fetchItemsResponse(Result<[Item], Error>)
        case itemTapped(Item)
    }

    // MARK: - Dependencies
    @Dependency(\.apiClient) var apiClient

    // MARK: - Reducer Body
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

            case .itemTapped:
                return .none
            }
        }
    }
}
```

---

## View の実装例

```swift
import ComposableArchitecture
import SwiftUI

struct FeatureAView: View {
    // @Bindable により State の変化を自動的に購読
    @Bindable var store: StoreOf<FeatureAReducer>

    var body: some View {
        List(store.items) { item in
            Text(item.title)
                .onTapGesture {
                    store.send(.itemTapped(item))
                }
        }
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
```

---

## 依存性の注入（Dependency）

TCA の `@Dependency` を用いて副作用を持つ処理を注入可能な形で管理します。  
これにより、本番・テスト・プレビュー環境で異なる実装を差し替えられます。

```swift
// 定義
extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// テスト時の差し替え
let store = TestStore(initialState: FeatureAReducer.State()) {
    FeatureAReducer()
} withDependencies: {
    $0.apiClient = .mock  // モック実装に差し替え
}
```

---

## テスト方針

- **`TestStore`** を使用し、`Action` の送信に対して `State` の変化を逐一検証する
- **Effect** が返す `Action` も `await store.receive(...)` で検証する
- 副作用は `@Dependency` 経由で注入し、テストではモックに差し替える

```swift
import Testing
import ComposableArchitecture

@Suite("FeatureA")
struct FeatureAReducerTests {

    @Test("onAppear でアイテムが取得される")
    func fetchItemsOnAppear() async {
        let mockItems = [Item(id: 1, title: "テスト")]

        let store = TestStore(initialState: FeatureAReducer.State()) {
            FeatureAReducer()
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

## 画面遷移

画面遷移は TCA の **Navigation** 機能（`@Presents` / `NavigationStack` との統合）で管理します。

```swift
@Reducer
struct AppReducer {
    @ObservableState
    struct State {
        var featureA = FeatureAReducer.State()
        @Presents var destination: Destination.State?
    }

    enum Action {
        case featureA(FeatureAReducer.Action)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    enum Destination {
        case featureB(FeatureBReducer)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.featureA, action: \.featureA) {
            FeatureAReducer()
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
```

---

## 参考リンク

- [The Composable Architecture — GitHub](https://github.com/pointfreeco/swift-composable-architecture)
- [TCA ドキュメント](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)
- [Point-Free エピソード](https://www.pointfree.co)

# pinNest UI/UX ガイドライン

## 概要

本ドキュメントは pinNest の UI/UX 設計方針を定めます。
Apple の **Human Interface Guidelines（HIG）** をベースとし、iOS ネイティブの体験に沿った一貫性のある UI を提供することを目的とします。

参考: [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 設計の基本原則

Apple HIG が掲げる 3 つの原則をプロジェクト全体で遵守します。

| 原則 | 説明 |
|------|------|
| **Clarity（明確さ）** | テキスト・アイコン・カラーを使って情報を正確に伝える。装飾より機能を優先する |
| **Deference（従順さ）** | コンテンツを主役にする。UI はコンテンツを引き立てる背景として機能する |
| **Depth（奥行き）** | 視覚的な階層・アニメーション・トランジションで空間的な理解を助ける |

---

## カラー

### システムカラーを優先する

独自カラーより `Color` のシステムカラーを優先します。ダークモード・アクセシビリティへの対応が自動的に得られます。

```swift
// Good
Text("タイトル").foregroundStyle(.primary)
Rectangle().fill(Color(.systemBackground))
Button("保存") { }.tint(.blue)  // システムブルー

// Bad: ハードコードしたカラー値
Text("タイトル").foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
```

### カラーの役割定義

| 役割 | 使用するカラー |
|------|--------------|
| プライマリテキスト | `.primary` |
| セカンダリテキスト | `.secondary` |
| 背景 | `Color(.systemBackground)` / `Color(.secondarySystemBackground)` |
| アクセントカラー | `.tint`（アプリ全体で統一） |
| 危険操作 | `.red` |
| 成功・完了 | `.green` |

### ダークモード対応

- ハードコードしたカラーを使用する場合は `Color(light:dark:)` で両モードを定義する
- `Assets.xcassets` の Color Set でライト / ダークを設定する

---

## タイポグラフィ

### Dynamic Type を必ず使用する

固定サイズの `font(.system(size: 14))` ではなく、Dynamic Type スタイルを使用します。
これによりユーザーのフォントサイズ設定が反映されます。

```swift
// Good
Text("見出し").font(.headline)
Text("本文").font(.body)
Text("注釈").font(.caption)

// Bad
Text("見出し").font(.system(size: 17, weight: .semibold))
```

### テキストスタイルの使い分け

| スタイル | 用途 |
|---------|------|
| `.largeTitle` | 画面タイトル（NavigationStack の大見出し） |
| `.title` / `.title2` / `.title3` | セクションタイトル |
| `.headline` | リストアイテムのメインラベル |
| `.body` | 通常の本文テキスト |
| `.subheadline` / `.callout` | 補足情報 |
| `.footnote` / `.caption` | メタ情報・タイムスタンプ |

---

## スペーシング・レイアウト

### 余白は 8pt グリッドを基準にする

| サイズ | 用途 |
|-------|------|
| `4pt` | 最小マージン（アイコンとラベルの間など） |
| `8pt` | コンポーネント内の標準スペース |
| `16pt` | コンテンツの水平パディング（画面端からの余白） |
| `24pt` | セクション間のスペース |
| `32pt` | 大きなセクション区切り |

```swift
// Good
VStack(spacing: 8) { ... }
    .padding(.horizontal, 16)

// Bad: 中途半端な値
VStack(spacing: 11) { ... }
    .padding(.horizontal, 13)
```

### Safe Area を尊重する

コンテンツが Safe Area に重ならないようにします。カスタム背景など意図的にはみ出す場合のみ `.ignoresSafeArea()` を使用します。

---

## コンポーネント

### ネイティブコンポーネントを優先する

カスタム実装より標準コンポーネントを優先します。OS アップデートで自動的に改善されます。

| 用途 | 使用するコンポーネント |
|------|----------------------|
| リスト表示 | `List` |
| 画面遷移 | `NavigationStack` / `NavigationLink` |
| タブ切り替え | `TabView` |
| モーダル | `.sheet` / `.fullScreenCover` |
| アラート・確認 | `.alert` / `.confirmationDialog` |
| アクション選択 | `.contextMenu` / `Menu` |
| 入力 | `TextField` / `Toggle` / `Picker` |

### ボタン

- 主要アクションは `.buttonStyle(.borderedProminent)` を使用する
- 危険な操作（削除など）には `.tint(.red)` を付与する
- アイコンボタンには `Label` を使い、アクセシビリティラベルを持たせる

```swift
// 主要アクション
Button("保存") { store.send(.saveButtonTapped) }
    .buttonStyle(.borderedProminent)

// 危険アクション
Button(role: .destructive) {
    store.send(.deleteButtonTapped)
} label: {
    Label("削除", systemImage: "trash")
}

// アイコンボタン
Button {
    store.send(.addButtonTapped)
} label: {
    Label("追加", systemImage: "plus")
        .labelStyle(.iconOnly)
}
```

### アイコン

- アイコンは **SF Symbols** を使用する（独自画像は不要な限り使わない）
- `Image(systemName:)` で呼び出し、サイズ調整は `.imageScale()` または `.font()` で行う

```swift
// Good
Image(systemName: "pin.fill")
    .imageScale(.medium)

// サイズをテキストに合わせる
Label("ピン留め", systemImage: "pin.fill")
    .font(.body)
```

---

## ナビゲーション

### NavigationStack を使用する

- `NavigationStack` + `NavigationLink` で画面遷移を管理する
- TCA の `@Presents` / `navigationDestination` と組み合わせて状態管理する

### 画面タイトル

- 各画面には `.navigationTitle()` を必ず設定する
- 一覧画面は `.navigationBarTitleDisplayMode(.large)`、詳細・編集画面は `.navigationBarTitleDisplayMode(.inline)` を使用する

```swift
NavigationStack {
    PinListView(store: store)
        .navigationTitle("ピン一覧")
        .navigationBarTitleDisplayMode(.large)
}
```

---

## フィードバック

ユーザー操作に対して適切なフィードバックを返します。

| 状況 | フィードバック手段 |
|------|-----------------|
| ロード中 | `ProgressView()` |
| 操作の成功 | `.sensoryFeedback(.success, trigger:)` |
| エラー | `.alert` でメッセージ表示 + `.sensoryFeedback(.error, trigger:)` |
| 削除・完了 | `.sensoryFeedback(.impact, trigger:)` |

```swift
// ハプティクスフィードバック
List { ... }
    .sensoryFeedback(.success, trigger: store.isSaved)
```

---

## アクセシビリティ

HIG はアクセシビリティを必須要件として位置づけています。

### ラベルの付与

すべてのインタラクティブ要素にはアクセシビリティラベルを設定します。

```swift
// アイコンボタンには必ずラベルを付ける
Button {
    store.send(.addButtonTapped)
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel("ピンを追加")
```

### コントラスト比

- テキストとその背景のコントラスト比は **4.5:1 以上**（WCAG AA 準拠）を確保する
- システムカラーを使用していれば自動的に満たされる

### タップ領域

タップ可能な要素の最小サイズは **44×44pt** を確保します。

```swift
Button { ... } label: {
    Image(systemName: "ellipsis")
}
.frame(minWidth: 44, minHeight: 44)
```

### VoiceOver 対応

- 装飾的な画像には `.accessibilityHidden(true)` を付与する
- 複数要素をグループ化する場合は `.accessibilityElement(children: .combine)` を使用する

---

## アニメーション

- アニメーションは `.animation(.default, value:)` を使用し、変化のトリガーを明示する
- 過度なアニメーションはユーザーの集中を妨げるため避ける
- **Reduce Motion** 設定を尊重する

```swift
// Good: トリガーを明示した控えめなアニメーション
List { ... }
    .animation(.default, value: store.items)

// Reduce Motion に配慮
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .spring(duration: 0.3)
}
```

---

## 参考リンク

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Dynamic Type — Apple Developer](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)
- [アーキテクチャ方針](./architecture.md)
- [コーディング規約](./coding-conventions.md)

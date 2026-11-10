# pinNest コードレビュー（2026-04-21）

全体コードを5つの観点（TCAアーキテクチャ・Swift並行性・UI/UX・データ層・コード品質）でレビューした結果をまとめる。

---

## 総評

TCAアーキテクチャの理解度は高く、依存注入・Effect分離・アクセシビリティ対応が丁寧に実装されている。
最優先対応は「クラッシュリスクのある force unwrap」「PinDataStore のエラー無視」。

| 優先度 | 件数 |
|--------|------|
| Critical 🔴 | 3件 |
| High 🟠 | 6件 |
| Medium 🟡 | 8件 |
| Low 🟢 | 7件 |

---

## 🔴 Critical ~~（即修正推奨）~~ → ✅ 対応済み（2026-04-22）

### 1. Force unwrap によるクラッシュリスク

**対象**: `Shared/Utilities/ThumbnailCache.swift`

```swift
// 現状（クラッシュリスク）
FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!

// 修正案
guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
    throw ThumbnailCacheError.noCacheDirectory
}
```

`Features/PinCreate/PinCreateView.swift` でも同様に `FileManager.default.urls(...)[0]` の直接添字アクセスが存在する。`.first` + `guard` に置き換える。

---

### 2. MetadataClient の LPMetadataProvider にタイムアウトなし

**対象**: `Shared/Clients/MetadataClient.swift`

```swift
// 現状（永遠に返らないリスク）
let provider = LPMetadataProvider()
provider.startFetchingMetadata(for: url) { metadata, error in
    continuation.resume(...)
}
```

タイムアウト設定がないため、ネットワークが遅い URL で Effect が永遠に返らない。
5秒程度の `Task.sleep` キャンセルタスクを並走させて `continuation.resume(throwing: MetadataError.timeout)` を呼ぶ。

---

### 3. `update()` / `delete()` が対象未発見を無視

**対象**: `Shared/Clients/PinDataStore.swift`（約40行・65行）

```swift
// 現状（エラーなしで return）
guard let pin = try modelContext.fetch(...).first else { return }

// 修正案
guard let pin = try modelContext.fetch(...).first else {
    throw PinDataStoreError.pinNotFound(id)
}
```

ピンが見つからなくても成功と見なされる。Reducer 側はUI更新完了と判断してしまい、データが実際には更新されていないのにUIだけ変わるリスクがある。

---

## 🟠 High（近いうちに修正）

### 5. Reducer 実装方式の不統一（CLAUDE.md 違反）

**対象**: `Features/PinCreate/PinCreateReducer.swift`・`Features/PinDetail/TagPickerReducer.swift`

この2ファイルは `func reduce(into:action:)` を使用。他のすべての Reducer は `var body: some ReducerOf<Self>` を使用しており、CLAUDE.md の規約（State / Action / body の順）に違反している。

---

### 6. `saveButtonTapped` が 127 行の巨大 case

**対象**: `Features/PinCreate/PinCreateReducer.swift`（約137〜263行）

5種のコンテンツタイプ × 2モード（create / edit）の分岐が1つの case 内に混在している。コンテンツタイプごとに private メソッドへ抽出することで可読性・保守性が改善する。

```swift
// 改善イメージ
case .saveButtonTapped(let imageData, let videoPath, let pdfData):
    switch state.mode {
    case .create: return createEffect(state, imageData: imageData, videoPath: videoPath, pdfData: pdfData)
    case .edit(let pin): return editEffect(state, pin: pin, imageData: imageData, videoPath: videoPath, pdfData: pdfData)
    }
```

---

### 7. エラー時のUI通知欠落

**対象**: `Features/PinList/PinListReducer.swift`（約79〜81行）、`HistoryReducer.swift`、`SearchReducer.swift`

```swift
// 現状
case .pinsResponse(.failure):
    state.isLoading = false
    return .none  // ユーザーに何も伝えない

// 修正案
case let .pinsResponse(.failure(error)):
    state.isLoading = false
    state.errorMessage = error.localizedDescription
    return .none
```

ローディング中 → 何も表示されない という不可解な遷移になる。`State` に `errorMessage: String?` を追加してアラート表示する。

---

### 8. `filePath` の相対パス・絶対パス混在

**対象**: `Shared/Models/Pin.swift`（約19行）・`Shared/Utilities/ThumbnailCache.swift`

- URL ピンのサムネイル → 相対パス（`ThumbnailCache.save()` が返す）
- 画像・動画・PDF ファイル → `AppGroupContainer.filesURL` 配下の絶対パス

保存形式が混在しており、将来のサンドボックスパス変更時に既存データが壊れるリスクがある。
`Pin` に `absoluteFilePath: URL?` の computed property を追加し、変換を一元化する。

---

### 9. 削除したピンのサムネイルが残り続ける

**対象**: `Shared/Clients/PinDataStore.swift`（`delete()` メソッド）

`delete()` 内で `ThumbnailCache.remove()` が呼ばれていない。ピンを削除しても JPEG ファイルがストレージに蓄積し続ける。

```swift
// 修正案
func delete(id: UUID) throws {
    // ...
    if let filePath = pin.filePath, pin.contentType == .url {
        ThumbnailCache.remove(path: filePath)
    }
    modelContext.delete(pin)
    try modelContext.save()
}
```

---

### 10. AppReducer での子アクションインターセプトが3画面分重複

**対象**: `App/AppReducer.swift`（約101〜177行）

PinList / History / Search の3タブでほぼ同一の「edit → PinCreate 表示」パターンを繰り返し記述している。共通ヘルパーメソッドに抽出する。

---

## 🟡 Medium（スプリント内に対応）

### 11. `switch` 文での `default` 使用（CLAUDE.md 違反）

**対象**: `Features/PinCreate/PinCreateReducer.swift`（約20行）・`Features/PinCreate/PinCreateView.swift`（約94・115行）

CLAUDE.md で明示的に禁止されている `default` / `default: break` が残存している。全 case を網羅する形に修正する。

---

### 12. `onAppear` / `refresh` パターンの DRY 違反

**対象**: `Features/PinList/PinListReducer.swift`・`Features/History/HistoryReducer.swift`・`Features/Search/SearchReducer.swift`

3つの Reducer で全件取得 → ローディング制御の同一パターンが重複している。少なくとも `.onAppear` から `.refresh` への委譲で重複を削減できる。

---

### 13. `pinClient.update()` の7引数が繰り返しコード

お気に入りトグルのたびに全フィールドを渡す必要があり、フィールド追加時のバグ温床になっている。`NewPin` と同様の `UpdatePin` value type を導入するか、`updateFavorite(UUID, Bool)` を専用メソッドとして分離する。

---

### 14. 検索が全件メモリフィルター方式

**対象**: `Shared/Clients/PinDataStore.swift`（約78〜105行）

```swift
var pins = try modelContext.fetch(descriptor)  // 全件ロード
if !keyword.isEmpty {
    pins = pins.filter { ... }  // メモリでフィルター
}
```

ピン数が増えると遅延が顕著になる。可能な範囲で `#Predicate` を DB レイヤーに移行することを検討する。

---

### 15. ハードコードされたフォントサイズ（Dynamic Type 非準拠）

**対象**: `Features/PinList/PinCardView.swift`・`Features/PinDetail/PinDetailView.swift`・`Features/PinCreate/PinCreateView.swift`

`.font(.system(size: 32))` のような固定サイズが多数存在する。`.font(.title)` / `.font(.title2)` などの Dynamic Type スタイルに統一する。

主な箇所：

| ファイル | 現状 | 修正案 |
|---------|------|--------|
| `PinCardView.swift` | `.font(.system(size: 32))` | `.font(.title3)` |
| `PinCardView.swift` | `.font(.system(size: 36))` | `.font(.title)` |
| `PinDetailView.swift` | `.font(.system(size: 56))` | `.font(.system(.largeTitle))` |
| `PinCreateView.swift` | `.font(.system(size: 40))` | `.font(.title)` |

---

### 16. タップ領域の不足

**対象**: `Features/PinList/PinCardView.swift`（約213〜214行）

お気に入りボタンが `frame(width: 36, height: 36)` で Apple HIG の最小サイズ（44×44pt）未満。

```swift
// 修正案
Button { ... } label: { ... }
    .frame(width: 44, height: 44)
    // または
    .contentShape(Rectangle())
```

---

### 17. スペーシングが 8pt グリッド外

複数 View で `spacing: 3`・`spacing: 6`・`spacing: 12` などの中途半端な値が混在している。8 / 16 / 24 / 32pt に統一する。

主な箇所：

| ファイル | 現状 | 推奨値 |
|---------|------|--------|
| `AppView.swift` | `spacing: 12` | `spacing: 16` |
| `PinListView.swift` | `.padding(.vertical, 2)` | `4` or `8` |
| `PinCardView.swift` | `VStack spacing: 3` | `4` |
| `PinCreateView.swift` | `spacing: 6` | `8` |

---

### 18. SwiftData マイグレーション戦略の欠落

**対象**: `Shared/Clients/PinClient.swift`（約67〜74行）

`ModelConfiguration` にスキーマバージョニングが未定義。`Pin`・`Tag` モデルを将来変更した際にユーザーデータが破損するリスクがある。スキーマバージョンと `ModelConfiguration` のマイグレーションポリシーを定義する。

---

## 🟢 Low（将来対応でOK）

| # | 内容 | 対象ファイル |
|---|------|------------|
| 19 | `HapticClient` で UserDefaults チェックが3メソッドに重複 | `Shared/Clients/HapticClient.swift` |
| 20 | JPEG 圧縮品質が `ThumbnailCache`（0.7）と `DemoData`（0.85）で不統一。定数化して共有 | `ThumbnailCache.swift`・`DemoData.swift` |
| 21 | `AppGroupContainer.makeDirectory()` のディレクトリ作成失敗が `try?` で無視される | `Shared/Utilities/AppGroupContainer.swift` |
| 22 | `SettingsReducer.onAppear` で Bundle 直接読み取り（テスト不可）。`AppInfoClient` dependency 化を検討 | `Features/Settings/SettingsReducer.swift` |
| 23 | Analytics イベントに結果件数・成功フラグが含まれない（例: `searchPerformed(resultCount:)`） | `Shared/Clients/AnalyticsClient.swift` |
| 24 | 履歴タイムラインのピン装飾アイコンに `.accessibilityHidden(true)` がない | `Features/History/HistoryView.swift` |
| 25 | `FilterChip` に `.accessibilityLabel()` がない | `Features/PinList/PinListView.swift` |

---

## 優れている点

- **TCA パターンの理解度が高い**: `@Presents` / `@Dependency` / `Effect` の使い方が正確
- **アクセシビリティ対応**: 大半のインタラクティブ要素に `accessibilityLabel` が付与されている
- **SF Symbols の使い方**: 全体的に文脈に沿った適切な使用
- **システムカラーの徹底**: `.primary` / `.secondary` / `Color(.systemBackground)` 等を一貫して使用
- **エラーハンドリングの方針**: `Result` 型による Effect のエラー伝播が統一されている
- **Analytics / Crashlytics の統合**: イベント設計が整理されており、Reducer への組み込みが一貫している
- **コメントの品質**: トリッキーなコードに明確な説明コメントが添えられている

---

*レビュー実施日: 2026-04-21*

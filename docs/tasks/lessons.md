# Lessons Learned

## 2026-06-16: オンデバイス要約は CoreML ではなく Foundation Models

### 学び
- iOS 26+ では「テキスト要約」に CoreML 同梱モデルを使うべきではない（数百MB・トークナイザ自前・低品質）。
  Apple の **Foundation Models framework**（`import FoundationModels` / `SystemLanguageModel`）が正解。
  モデル同梱不要・完全オンデバイス・高品質。
- ユーザーが「CoreML で」と指定しても、タスク（要約）に対する最適エンジンを技術的に提示して確認を取る。

### 実装上の要点
- `SystemLanguageModel.default.availability` を必ず判定（`.unavailable(.deviceNotEligible / .appleIntelligenceNotEnabled / .modelNotReady)`）。
  Apple Intelligence 非対応端末・未有効時はボタンを無効化して理由を表示する。
- context 上限があるため入力テキストは事前に truncate（約 6,000 字）してから `LanguageModelSession.respond(to:)` に渡す。
- `import FoundationModels` / `import PDFKit` は専用クライアントファイルに閉じ込め、Reducer / View に漏らさない。
- **PinClient のクロージャ literal を構築している箇所は複数ある**（`liveValue` だけでなく `DemoData.swift` のプレビュー用も）。
  プロパティ追加時は両方を更新しないと「missing argument for parameter」ビルドエラーになる。

### スキーマ変更（重要・ハマった）
- **単一 @Model クラス運用では VersionedSchema を複数に増やしてはいけない。**
  `SchemaV1` と `SchemaV2` が両方とも同じ現行 `Pin` クラスを参照すると、チェックサムが一致して
  `ModelContainer` 初期化時に **"Duplicate version checksums detected" で起動クラッシュ**する（データ有無に関係なく毎回）。
- **オプショナルフィールドの追加は自動 lightweight マイグレーションで吸収される。**
  → スキーマは現行モデルを指す **1 つだけ**（`CurrentSchema`）にし、`stages` は空でよい。明示ステージも別バージョンも不要。
- 旧形状を別バージョンとして正しく表現するには、各 VersionedSchema が「そのバージョン時点のモデル型」を
  スナップショットする必要があるが、単一クラス運用では不可能。複数バージョンが本当に必要になったら
  モデル型のスナップショットを別途用意すること。

## 2026-03-11: SwiftUI `.contextMenu` のタイプ別メニュー遅延問題

### 症状
- 長押しメニューで共通項目のみが先に表示され、タイプ固有項目が遅れて表示される
- SwiftUI の `.contextMenu` 内の描画が遅延する

### 試したが効果がなかったアプローチ
1. `if`/`switch` を `.contextMenu` の外に出す
2. `ForEach` + `PinMenuAction` 配列で事前構築
3. `contentType` を plain value で渡す
4. UIKit `UIContextMenuInteraction` で `.contextMenu` をバイパス → メニュー自体が表示されなくなった

### 反省点
- **同じアプローチの変形を繰り返した**: SwiftUI `.contextMenu` の中身を変え続けたが根本原因の検証がなかった
- **ビルド成功 ≠ 修正完了**: UI の挙動バグはシミュレータ実行でしか確認できない
- **再計画しなかった**: 2回失敗した時点で立ち止まるべきだった

### ルール化
- **3回同じ系統のアプローチで失敗 → 必ず Plan Mode に入り根本原因を再調査**
- **UI 挙動バグの修正は「シミュレータでの動作確認」を完了条件にする**
- **UIKit ↔ SwiftUI の混在は小さな PoC で動作確認してから本実装に組み込む**
- **修正前に再現条件を明確にする**（どの画面、どの操作、どういう状態のとき）

### 未解決
- `.contextMenu` のタイプ固有メニュー遅延の根本原因は未特定
- 仮説: SwiftData `@Model` の `contentType` プロパティアクセスが遅延している可能性
- 仮説: SwiftUI が `ForEach` の動的コンテンツを `UIDeferredMenuElement` に変換している可能性
- 次のアプローチ: まず根本原因を特定するためのデバッグ（`os_log` / `os_signpost` でタイミング計測）

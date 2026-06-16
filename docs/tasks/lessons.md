# Lessons Learned

## 2026-06-16: ヴィジュアルリグレッションテスト（swift-snapshot-testing）導入

### 固定環境
- VRT の固定機種は **iPhone 17 Pro / iOS 26.1**（実機 indullのiPhone17pro に一致）。
  `iPhone 16`（無印）は OS 26.1 のシミュレータにインストールされていない → destination で見つからない。
- 記録・検証は必ず同一機種・OS で行う。機種/OS が変わるとピクセル差分で全滅する。

### ハマりどころ（重要）
- **`.sizeThatFits` は `Color + aspectRatio(.fit)` のサムネイルを高さ 0 に潰す。**
  圧縮フィッティング（layoutFittingCompressedSize）は固有高さの無い View を最小化するため。
  実機グリッドは親が幅を与え高さを導出する → 再現には **幅固定 + `UIHostingController.sizeThatFits(in: (width, .greatestFiniteMagnitude))` で高さ実測 → `.fixed(width:height:)` で撮る**。
  （`SnapshotSupport.assertSnapshotInBothColorSchemes` 参照）
- **`-parallel-testing-enabled NO` 必須。** Swift Testing はデフォルトでシミュレータ Clone を複数並列起動し、
  共有の `__Snapshots__/` を同時に記録/読込みしてレース（pass/fail が不整合に）。記録・検証とも直列で実行する。
- **記録モード制御は `SNAPSHOT_TESTING_RECORD` 環境変数**（`missing` = 無い分だけ記録 / `all` = 全上書き）。
  撮り直し時は古い参照を消した上で `all`、または確実に削除してから `missing`。
- **バックグラウンドの Bash は cwd がプロジェクトルートと異なることがある** → `xcodebuild -project` も `rm` も**絶対パス**で。
  特に `rm -rf` は対象が無くてもエラーを出さないので「削除成功」表示を鵜呑みにしない（残数を `find | wc -l` で検証）。

### 検証
- `assertSnapshot` の `precision: 1.0` / `perceptualPrecision: 0.98`（`.ultraThinMaterial` 等の微差を許容）。
- 記録 → コミット → 比較モード再実行で全パスを確認、が決定論性の証明。完了の証跡にする。
- glassEffect を使う floating bar / FAB は非決定論リスクが高いので対象から外し、純粋コンポーネントから着手した。

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

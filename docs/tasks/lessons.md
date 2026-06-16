# Lessons Learned

## 2026-06-17: VRT の CI 化で 9 回失敗した振り返り（仕様 vs 進め方）

PR #6 マージ(`b3fba25`)以降、CI green(`dc8cc0d`)まで 9 回の修正を要した。原因を分けて分析。

### 仕様（環境）起因 — 避けがたかったもの
- GitHub-hosted runner に **iOS 26.1 ランタイムが無い**（26.2/26.4/26.5 のみ）。**Apple も 26.1 シムを配布していない**ため後入れ不可 → ローカル(26.1)完全一致は物理的に不可能。
- **Xcode は自分より新しいランタイムを使えない**（26.1 で 26.5 シム不可）。runner の Xcode/ランタイム組み合わせは固定で選択肢が狭い。
- **最新 Xcode 26.5 + TCA 1.23.1 が非互換**（`WritableKeyPath … does not conform to Sendable`）。ライブラリ×コンパイラのスキューで事前予測ほぼ不可。
- スナップショットは Xcode/iOS バージョンで描画が変わる（26.1↔26.2 で 20枚全相違）→ baseline は runner 側で記録するしかない。
→ 本質的に不可避だったのは「26.5 で TCA が壊れる」「26.1 入手不可」の 2 点のみ。

### AI／進め方起因 — 減らせた失敗（過半数）
1. **環境調査をせずローカル前提で着手した**（最大の失敗）。最初に「環境を出力するだけの cheap な診断 run」を1本回せば、ランタイム不在→Xcode非互換→TCA崩れ→26.1入手不可の連鎖を1回で把握できた。
2. **既知の iOS-CI 定番を前倒ししなかった**。`-skipMacroValidation` / ダミー `GoogleService-Info.plist` / `-enableCodeCoverage NO` / record の `TEST_RUNNER_` は「SPMマクロ+Firebase+snapshot 記録を CI で回す」定番要件。最初のドラフトに入れていれば 3〜4 回削れた。
3. **検証不足による誤診**（最悪の1回）。artifact の存在＋「ローカルと0差分」で成功判定したが、実際はテストが destination エラーで走っていなかっただけ。「runner≠ローカルなら差分が出るはず」という自分の仮説と矛盾する0差分を赤信号にしなかった。
4. **推測で2回失敗**（record の env を host→`SIMCTL_CHILD_`→`TEST_RUNNER_`）。一次情報を先に確認すれば1回で済んだ。
5. **仮説の検証順序が非効率**。「iOS 26.1 を入れて一致」を、配布有無を確認せず CI で試した。

### 再発防止（CI・高コストround-trip全般）
- **偵察ファースト**: 新環境では本実装前に「環境を出力するだけ」の run を1本。教訓「2回失敗→Plan Mode」を CI では**1回目から**適用する。
- **既知要件のチェックリスト化**: iOS×TCA×Firebase×snapshot CI = `-skipMacroValidation` / ダミー plist / `TEST_RUNNER_SNAPSHOT_TESTING_RECORD` / runner 基準 baseline / record upload は `if: always()`。
- **「成功」判定を厳格化**: exit コードや成果物の有無ではなく、**意図した処理が実行された証跡**（テスト件数・`Recorded snapshot`・差分の有無）で確認。自分の仮説と矛盾する観測は必ず深掘り。
- **推測より一次情報**: 未知の機構（env 伝播など）を当て推量で CI に投げない。
（詳細な技術手順はメモリ `vrt-snapshot-testing.md` 参照）

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

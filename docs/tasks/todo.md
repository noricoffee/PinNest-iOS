# ヴィジュアルリグレッションテスト（VRT）導入

方針: A = `swift-snapshot-testing`（Point-Free）で決定論的スナップショットを CI ゲート化。

固定環境: **iPhone 17 Pro / iOS 26.1**（記録・検証は同一機種・OS で行うこと）
※ iPhone 16 無印は OS 26.1 シミュレータ未インストールのため不可。実機 iPhone 17 Pro に一致させた。

## タスク

- [x] テスト構成の調査（pinNestTests はスタンドアロン同期ターゲット）
- [x] スナップショット共通ヘルパー作成（`pinNestTests/Snapshot/SnapshotSupport.swift`）
- [x] PinCardView スナップショットスイート作成（`pinNestTests/Snapshot/PinCardSnapshotTests.swift`）
- [x] Xcode で `swift-snapshot-testing` を `pinNestTests` ターゲットへ追加（1.19.2）
- [x] 参照画像を記録（12 枚）し検証パス（要 `__Snapshots__/` をコミット）
- [x] 比較モードで再実行し全パス確認（決定論性の検証）→ `** TEST SUCCEEDED **`
- [x] 対象 View を拡大（PinList / History / PinDetail / Settings をフルスクリーンで追加 = 8 枚）
      ※ `EmptyReducer` + 固定 State + `.device(config: .iPhone13Pro)` 方式。glassEffect は ContentView 側のみで各画面には無し
- [x] CI ワークフロー追加（`.github/workflows/vrt.yml`、GitHub-hosted / main への PR）
- [x] CI 参照画像を runner(26.2) 基準で記録・コミット → **verify green 確認済み**（10 tests / 20 枚 pass）

## CI 構成（`.github/workflows/vrt.yml`）— 確定

- runner: `macos-26` / **Xcode 26.2 / iOS 26.2 / iPhone 17 Pro**
- トリガー: `pull_request`(main) で検証 / `workflow_dispatch`(mode=record) で参照記録
- 失敗時は `TestResults.xcresult`（reference/取得/差分画像つき）を artifact 化
- 参照画像は **runner(26.2) 基準**（ローカル26.1とは別）。View 追加時は `mode=record` → artifact `recorded-snapshots` を差し替えコミット
- 必須フラグ: `-skipMacroValidation` / `-enableCodeCoverage NO` / `-parallel-testing-enabled NO`
- record の env は `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all`（testmanagerd 経由のため）
- ダミー `GoogleService-Info.plist` を CI で生成（gitignore のため）
- 詳細な落とし穴は `lessons.md` / メモリ `vrt-snapshot-testing.md` 参照

## 実行コマンド（確定）

記録（撮り直し時）:
```
SNAPSHOT_TESTING_RECORD=all xcodebuild test \
  -project /ABS/PATH/pinNest.xcodeproj -scheme pinNest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -only-testing:pinNestTests/PinCardSnapshotTests -parallel-testing-enabled NO
```
検証（CI / 通常）:
```
xcodebuild test \
  -project /ABS/PATH/pinNest.xcodeproj -scheme pinNest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -only-testing:pinNestTests/PinCardSnapshotTests -parallel-testing-enabled NO
```
※ `-parallel-testing-enabled NO` は Clone 並列による参照ファイルレース回避のため必須。

## レビュー

- `PinCardView` × 5 タイプ + favorite × light/dark = 12 スナップショット。全パス。
- `.sizeThatFits` ではサムネイル（Color+aspectRatio）が高さ 0 に潰れる問題を、
  幅固定 + 高さ実測 + `.fixed` 方式で解決（`SnapshotSupport` 参照）。詳細は `lessons.md`。

## 手動手順（SPM パッケージ追加）

1. Xcode で `pinNest.xcodeproj` を開く
2. File > Add Package Dependencies…
3. URL: `https://github.com/pointfreeco/swift-snapshot-testing`
4. Dependency Rule: Up to Next Major Version（1.x）
5. Add Package → プロダクト `SnapshotTesting` を **`pinNestTests`** ターゲットに紐付け
6. 追加後、`SnapshotSupport.swift` の `import SnapshotTesting` エラーが解消されることを確認

## 決定論性メモ

- PinCardView は相対日付を描画しない → Pin を固定すれば決定論的
- サムネイルは filePath = nil でプレースホルダー分岐 → ディスク依存なし
- `.ultraThinMaterial`（blur）は perceptualPrecision 0.98 で許容
- glassEffect を使う floating bar / FAB は非決定論リスクが高いため後回し

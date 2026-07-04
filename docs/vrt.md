# ヴィジュアルリグレッションテスト（VRT）運用ガイド

`swift-snapshot-testing`（Point-Free）による決定論的スナップショットを CI ゲートとして運用する。
導入時の落とし穴の詳細は [tasks/lessons.md](./tasks/lessons.md)（2026-06-17 の項）を参照。

---

## 固定環境

| 環境 | 機種 / OS | 用途 |
|------|-----------|------|
| ローカル | iPhone 17 Pro / iOS 26.1 | 開発時の記録・検証 |
| CI（GitHub-hosted） | `macos-26` / Xcode 26.2 / iOS 26.2 / iPhone 17 Pro | PR ゲート |

- 記録と検証は**同一機種・同一 OS** で行うこと（バージョンが違うと描画が変わり全滅する）
- 参照画像は **runner(26.2) 基準**。ローカル 26.1 とは別物として扱う
- iPhone 16 無印は OS 26.1 シミュレータ未インストールのため不可

## CI 構成（`.github/workflows/vrt.yml`）

- トリガー: `pull_request`(main) で検証 / `workflow_dispatch`(mode=record) で参照記録
- 失敗時は `TestResults.xcresult`（reference / 取得 / 差分画像つき）を artifact 化
- **View 追加時の手順**: `mode=record` で実行 → artifact `recorded-snapshots` をダウンロードし `__Snapshots__/` を差し替えてコミット
- 必須フラグ: `-skipMacroValidation` / `-enableCodeCoverage NO` / `-parallel-testing-enabled NO`
- record 時の env は `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all`（testmanagerd 経由のため `TEST_RUNNER_` プレフィックスが必要）
- ダミー `GoogleService-Info.plist` を CI で生成する（gitignore のため）

## 実行コマンド

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

## テスト構成

- 共通ヘルパー: `pinNestTests/Snapshot/SnapshotSupport.swift`
- スイート: `pinNestTests/Snapshot/PinCardSnapshotTests.swift`
- フルスクリーン View は `EmptyReducer` + 固定 State + `.device(config:)` 方式
- `pinNestTests` はスタンドアロン同期ターゲット（BUNDLE_LOADER なし）

## 決定論性の注意点

- 相対日付・ディスク依存を View に持ち込まない（Pin を固定すれば決定論的になる設計を保つ）
- `.sizeThatFits` はサムネイル（Color + aspectRatio）が高さ 0 に潰れる → 幅固定 + 高さ実測 + `.fixed` 方式を使う（`SnapshotSupport` 参照）
- `.ultraThinMaterial`（blur）は perceptualPrecision 0.98 で許容
- glassEffect を使う floating bar / FAB は非決定論リスクが高いため対象外

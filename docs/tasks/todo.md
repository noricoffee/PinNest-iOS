# 進行中タスク

> 運用ルール: 現在進行中のタスクのみを置く。完了したら教訓を [lessons.md](./lessons.md) に抽出し、
> このファイルから削除する（恒久的な手順・構成は docs/ 直下の該当ドキュメントへ昇格させる）。
> 過去のフェーズ別タスクログは [../archive/tasks.md](../archive/tasks.md) を参照。

## PinSnapshot リファクタ — 残検証（2026-07-01 実装完了）

実装は完了済み（詳細は [lessons.md](./lessons.md) 2026-07-01 の項）。
TCA 1.26.2 への更新で Xcode 27.2 でもビルド可能になった。以下が未達:

- [ ] CI（Xcode 27.2）での `xcodebuild test` パス確認
- [ ] `-com.apple.CoreData.ConcurrencyDebug 1` 起動で並行アクセス違反ゼロを確認

## CI の Xcode 27.2 移行 — 残作業

- [x] VRT の参照画像を `mode=record` で再記録し、差分を目視確認してコミット
- [ ] `mode=verify` で新しい参照画像と一致することを確認
- [ ] 履歴画面の表示位置が上に移動した原因を確認（iOS 27.2 で記録した参照画像で発覚。崩れはない）

## バックログ（優先度低）

- [ ] 🟡 実機（Apple Intelligence 対応端末）での AI 要約の生成品質・UX 確認
- [ ] 🟢 ピン一覧の並び替え
- [ ] 🟢 データのエクスポート
- [ ] 🟢 UI テスト

# 進行中タスク

> 運用ルール: 現在進行中のタスクのみを置く。完了したら教訓を [lessons.md](./lessons.md) に抽出し、
> このファイルから削除する（恒久的な手順・構成は docs/ 直下の該当ドキュメントへ昇格させる）。
> 過去のフェーズ別タスクログは [../archive/tasks.md](../archive/tasks.md) を参照。

## PinSnapshot リファクタ — 残検証（2026-07-01 実装完了）

実装は完了済み（詳細は [lessons.md](./lessons.md) 2026-07-01 の項）。
ローカルが Xcode 27.0 beta のみで TCA 1.23.1 が型チェック不能なため、以下が未達:

- [ ] Xcode 26.2（CI またはローカル）での型チェック・`xcodebuild test` パス確認
- [ ] `-com.apple.CoreData.ConcurrencyDebug 1` 起動で並行アクセス違反ゼロを確認

## バックログ（優先度低）

- [ ] 🟡 実機（Apple Intelligence 対応端末）での AI 要約の生成品質・UX 確認
- [ ] 🟢 ピン一覧の並び替え
- [ ] 🟢 データのエクスポート
- [ ] 🟢 UI テスト

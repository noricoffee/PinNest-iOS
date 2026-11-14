# pinNest ドキュメント

pinNest は SwiftUI + TCA で構築された iOS アプリです。
Claude Code 向けの前提・規約は、リポジトリルートの [CLAUDE.md](../CLAUDE.md) が起点です。

---

## ディレクトリ構成と役割

| 場所 | 役割 |
|------|------|
| `docs/` 直下 | **規範ドキュメント**（開発時に常時参照するもの）+ GitHub Pages 公開物 |
| `docs/tasks/` | **作業状態**: 進行中タスク（todo.md）と教訓の蓄積（lessons.md） |
| `docs/release/` | **リリース運用**: App Store Connect の手順・メタデータ |
| `docs/archive/` | **完了・歴史的ドキュメント**: 役目を終えたタスクログ・一回性のレビュー等 |

## ドキュメント一覧

### 規範（コード生成・変更時に従う）

| ドキュメント | 内容 |
|-------------|------|
| [architecture.md](./architecture.md) | TCA を用いたアーキテクチャ設計方針・実装例 |
| [coding-conventions.md](./coding-conventions.md) | Swift / SwiftUI / TCA のコーディング規約 |
| [ui-ux-guidelines.md](./ui-ux-guidelines.md) | Apple HIG ベースの UI/UX 設計方針 |
| [requirements.md](./requirements.md) | 機能要件・画面一覧・非機能要件 |
| [vrt.md](./vrt.md) | ヴィジュアルリグレッションテスト（VRT）の運用ガイド |

### 作業状態

| ドキュメント | 内容 |
|-------------|------|
| [tasks/todo.md](./tasks/todo.md) | 進行中タスク（完了したら削除し、教訓を lessons へ） |
| [tasks/lessons.md](./tasks/lessons.md) | 失敗・修正から得たパターンの蓄積（追記のみ） |

### リリース・公開物

| ドキュメント | 内容 |
|-------------|------|
| [release/app-store-connect-guide.md](./release/app-store-connect-guide.md) | App Store Connect 登録手順 |
| [release/app-store-metadata.md](./release/app-store-metadata.md) | App Store 入力用メタデータ（説明文・キーワード等） |
| [privacy-policy.md](./privacy-policy.md) | プライバシーポリシー（**GitHub Pages で公開中 — 移動・リネーム禁止**） |

---

## 運用ルール

1. **配置**: 新しいドキュメントは上記の役割に従って置く。迷ったら「常時参照するか？」で判断し、しないなら直下に置かない
2. **一回性のドキュメント**（コードレビュー・振り返り等）: `archive/<内容>-YYYY-MM-DD.md` の形式で日付を付けて `archive/` に置く
3. **todo.md は現在進行中のみ**: 完了したタスクは残さない。教訓は lessons.md へ、恒久的な手順・構成は docs/ 直下の該当ドキュメントへ昇格させる
4. **lessons.md は追記のみ**: 日付見出しで時系列に積む。削除・書き換えはしない
5. **公開 URL を壊さない**: `privacy-policy.md` と `_config.yml` は GitHub Pages（`https://noricoffee.github.io/PinNest-iOS/privacy-policy`）が App Store に登録されているため、docs 直下から動かさない
6. **CLAUDE.md との整合**: docs の構成を変えたら CLAUDE.md の参照テーブルも同時に更新する

---

## 参考リンク

- [The Composable Architecture — GitHub](https://github.com/pointfreeco/swift-composable-architecture)
- [TCA ドキュメント](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)

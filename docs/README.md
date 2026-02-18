# pinNest ドキュメント

## 概要

pinNest は SwiftUI で構築された iOS アプリケーションです。
ピン留め・メモ・コレクション管理などの機能を、モダンなアーキテクチャのもとで提供します。

---

## 技術スタック

| 技術 | バージョン | 用途 |
|------|-----------|------|
| Swift | 6.x | 主要言語 |
| SwiftUI | - | UI フレームワーク |
| The Composable Architecture (TCA) | 最新安定版 | アーキテクチャフレームワーク |
| Swift Concurrency | - | 非同期処理 |
| Swift Testing | - | ユニットテスト |

---

## ドキュメント一覧

| ドキュメント | 内容 |
|-------------|------|
| [architecture.md](./architecture.md) | TCA を用いたアーキテクチャ設計方針・実装例 |
| [coding-conventions.md](./coding-conventions.md) | Swift / SwiftUI / TCA のコーディング規約 |
| [ui-ux-guidelines.md](./ui-ux-guidelines.md) | Apple HIG ベースの UI/UX 設計方針 |
| [requirements.md](./requirements.md) | 機能要件・画面一覧・非機能要件 |
| [tasks.md](./tasks.md) | フェーズ別タスク一覧・進捗管理 |

---

## プロジェクト構成

```
pinNest/
├── App/                  # エントリポイント・ルート Reducer
├── Features/             # 機能単位のモジュール群
├── Shared/               # 共有コード（モデル・APIクライアント・拡張）
└── docs/                 # ドキュメント（本ディレクトリ）
```

詳細なディレクトリ構成は [architecture.md](./architecture.md#ディレクトリ構成) を参照してください。

---

## 開発方針

- **アーキテクチャ**: TCA（The Composable Architecture）を全面採用
- **状態管理**: 単方向データフローで State の変化を一元管理
- **テスト**: `TestStore` を用いてビジネスロジックを副作用込みで検証
- **依存性注入**: `@Dependency` により本番・テスト・プレビューで実装を差し替え可能

---

## 参考リンク

- [The Composable Architecture — GitHub](https://github.com/pointfreeco/swift-composable-architecture)
- [TCA ドキュメント](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)

# pinNest — Claude 向けプロジェクト設定

このファイルは Claude Code が毎回自動的に読み込むプロジェクト設定です。
以下の方針・規約を常に前提としてコードを生成・レビューしてください。

---

## プロジェクト概要

- **アプリ名**: pinNest
- **プラットフォーム**: iOS
- **言語**: Swift 6
- **UI フレームワーク**: SwiftUI
- **アーキテクチャ**: The Composable Architecture（TCA）
- **テストフレームワーク**: Swift Testing（`@Suite` / `@Test`）

---

## 必読ドキュメント

コードの生成・変更を行う際は、必ず以下の方針に従ってください。

| ドキュメント | 内容 | パス |
|-------------|------|------|
| アーキテクチャ方針 | TCA の設計・実装パターン | `docs/architecture.md` |
| コーディング規約 | 命名・ファイル構成・実装ルール | `docs/coding-conventions.md` |
| UI/UX ガイドライン | Apple HIG ベースの UI 設計方針 | `docs/ui-ux-guidelines.md` |

---

## 重要なルール（抜粋）

### アーキテクチャ

- すべての機能は `@Reducer` で実装する（State / Action / body の順に記述）
- ビジネスロジックは Reducer に集約し、View には書かない
- 副作用は `Effect` に隔離し、`@Dependency` 経由で注入する
- 画面遷移は TCA の `@Presents` / `NavigationStack` で管理する

### コーディング規約

- Reducer は `<機能名>Reducer`、View は `<機能名>View` と命名する
- Action の case はユーザー操作を `<UI要素><動詞>`（例: `addButtonTapped`）、Effect 結果を `<処理名>Response` とする
- `switch` の `default` は使用しない。全 case を網羅する
- テストは `TestStore` + `@Suite` / `@Test` で記述する

### UI/UX

- カラーはシステムカラー（`.primary` / `Color(.systemBackground)` など）を優先する
- フォントは Dynamic Type スタイル（`.body` / `.headline` など）を使用する
- スペーシングは 8pt グリッドを基準にする
- タップ可能な要素の最小サイズは 44×44pt を確保する
- SF Symbols をアイコンとして使用する
- アクセシビリティラベルをすべてのインタラクティブ要素に付与する

---

## ディレクトリ構成

```
pinNest/
├── App/          # @main エントリポイント・AppReducer
├── Features/     # 機能ごとのディレクトリ（<機能名>Reducer.swift / <機能名>View.swift）
├── Shared/       # Models / APIClient / Extensions
└── docs/         # プロジェクトドキュメント
```

---

## コード生成時のチェックリスト

- [ ] Reducer に State / Action / body が揃っているか
- [ ] Action の命名規則に従っているか
- [ ] View にビジネスロジックが混入していないか
- [ ] `switch` で全 case を網羅しているか（`default` を使っていないか）
- [ ] システムカラー・Dynamic Type を使用しているか
- [ ] アクセシビリティラベルが付与されているか
- [ ] テストは `TestStore` + `@Suite` / `@Test` で書かれているか

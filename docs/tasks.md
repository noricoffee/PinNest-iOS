# pinNest タスク一覧

要件定義は [requirements.md](./requirements.md) を参照してください。

## 凡例

| 記号 | ステータス |
|------|----------|
| ⬜ | 未着手 |
| 🔄 | 進行中 |
| ✅ | 完了 |

| 優先度 | 意味 |
|--------|------|
| 🔴 | 高（MVP・ブロッカー） |
| 🟡 | 中（早期リリースに含めたい） |
| 🟢 | 低（将来対応） |

---

## フェーズ 1: 環境構築・基盤

- ⬜ 🔴 プロジェクトセットアップ（Xcode / Swift Package Manager）
- ⬜ 🔴 TCA パッケージの導入
- ⬜ 🔴 AppReducer / ルート NavigationStack の実装
- ⬜ 🔴 ディレクトリ構成の整備（App / Features / Shared）
- ⬜ 🔴 Dependency プロトコルの定義（APIClient など）

---

## フェーズ 2: 認証

- ⬜ 🔴 認証画面 UI（ログイン / サインアップ）
- ⬜ 🔴 AuthReducer の実装
- ⬜ 🔴 サインアップ処理
- ⬜ 🔴 ログイン処理
- ⬜ 🔴 ログアウト処理
- ⬜ 🟡 パスワードリセット
- ⬜ 🟡 アカウント削除
- ⬜ 🟢 SNS ログイン（Apple / Google）

---

## フェーズ 3: ピン管理（MVP コア機能）

- ⬜ 🔴 ピン一覧画面（PinListView / PinListReducer）
- ⬜ 🔴 ピン作成画面（PinCreateView / PinCreateReducer）
- ⬜ 🔴 ピン詳細画面（PinDetailView / PinDetailReducer）
- ⬜ 🔴 ピン編集機能
- ⬜ 🔴 ピン削除機能（スワイプ削除 / 確認アラート）
- ⬜ 🟡 お気に入り登録・解除
- ⬜ 🟢 並び替え

---

## フェーズ 4: コレクション管理

- ⬜ 🔴 コレクション一覧画面
- ⬜ 🔴 コレクション作成・編集・削除
- ⬜ 🔴 コレクションへのピン追加・移動
- ⬜ 🟢 コレクションの共有

---

## フェーズ 5: 検索・タグ

- ⬜ 🟡 検索画面（SearchView / SearchReducer）
- ⬜ 🟡 キーワード検索
- ⬜ 🟡 タグの作成・削除
- ⬜ 🟡 ピンへのタグ付け
- ⬜ 🟡 タグ一覧表示
- ⬜ 🟡 タグによるフィルタ
- ⬜ 🟡 日付・作成順ソート

---

## フェーズ 6: 設定

- ⬜ 🔴 設定画面（SettingsView / SettingsReducer）
- ⬜ 🔴 アプリバージョン・ライセンス表示
- ⬜ 🟡 表示テーマ切り替え（ライト / ダーク / システム）
- ⬜ 🟢 通知設定
- ⬜ 🟢 データのエクスポート

---

## フェーズ 7: テスト・品質

- ⬜ 🔴 AuthReducer のユニットテスト
- ⬜ 🔴 PinListReducer のユニットテスト
- ⬜ 🔴 PinCreateReducer のユニットテスト
- ⬜ 🟡 SearchReducer のユニットテスト
- ⬜ 🟡 SettingsReducer のユニットテスト
- ⬜ 🟡 アクセシビリティ検証（VoiceOver / Dynamic Type）
- ⬜ 🟢 UI テスト

---

## フェーズ 8: リリース準備

- ⬜ 🔴 App Icon / スプラッシュ画面
- ⬜ 🔴 App Store Connect 登録
- ⬜ 🔴 プライバシーポリシー
- ⬜ 🔴 TestFlight 配布
- ⬜ 🔴 App Store 審査申請

---

## 変更履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-19 | 初版作成 |

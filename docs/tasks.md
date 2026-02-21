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

## フェーズ 0: UI プロトタイプ（イメージ確認用）

- ✅ 🔴 ホーム画面 UI（PinListView / PinCardView）
  - ✅ 🔴 2カラム マソンリーグリッド
  - ✅ 🔴 種別フィルターチップ（横スクロール）
  - ✅ 🔴 フローティング TabBar（ホーム / 履歴 / 検索）
  - ✅ 🔴 フローティング FAB（＋ボタン）
  - ✅ 🔴 FAB 展開メニュー（コンテンツタイプ選択 / 暗転オーバーレイ / ＋↔× 切り替え）
- ✅ 🔴 ピン作成画面 UI（PinCreateView）
  - ✅ 🔴 コンテンツタイプ切り替え pill（横スクロール）
  - ✅ 🔴 URL 入力（TextField + クリアボタン）
  - ✅ 🔴 テキスト入力（TextEditor）
  - ✅ 🔴 画像選択（PhotosPicker / `.images`）・選択後サムネイル表示
  - ✅ 🟡 動画選択（PhotosPicker / `.videos`）・選択済み表示
  - ✅ 🟡 PDF インポート（`.fileImporter` / `.pdf`）・ファイル名表示
  - ✅ 🔴 タイトル入力（TextField）
  - ✅ 🔴 メモ入力（TextEditor、任意）
  - ✅ 🔴 タイトル自動補完（URL/テキストは本文から・空欄時は日時 `yyyy-MM-dd'T'HH:mm:ss`）
- ✅ 🔴 履歴画面 UI（HistoryView）
- ✅ 🔴 ピン詳細画面 UI（PinDetailView）
  - ✅ 🔴 タイプ別詳細表示（URL / 画像 / 動画 / PDF / テキスト）
  - ✅ 🔴 追加日時・コンテンツタイプ表示（metaHeader）
  - ✅ 🔴 URL タイプ: サムネイル・ドメイン・「Safari で開く」ボタン
  - ✅ 🔴 テキストタイプ: 全文表示
  - ✅ 🔴 PinListView / SearchView のカードタップ → モーダル表示
- ⬜ 🟡 コレクション詳細画面 UI（CollectionDetailView）
- ✅ 🟡 検索画面 UI（SearchView）
  - ✅ 🟡 標準検索バー（`.searchable`）によるリアルタイム検索
  - ✅ 🟡 タイトル・subtitle・本文の部分一致検索
  - ✅ 🟡 結果: マソンリーグリッド（PinCardView 再利用）
  - ✅ 🟡 空状態 / 結果なし状態（ContentUnavailableView）
- ⬜ 🟡 設定画面 UI（SettingsView）

> ⚠️ このフェーズは UI の見た目確認用。TCA Reducer・SwiftData は未実装。確認完了後に各フェーズで本実装を行う。

---

## フェーズ 1: 環境構築・基盤

- ✅ 🔴 プロジェクトセットアップ（Xcode / Swift Package Manager）
- ✅ 🔴 TCA パッケージの導入
- ✅ 🔴 AppReducer / ルート NavigationStack の実装
- ✅ 🔴 ディレクトリ構成の整備（App / Features / Shared）
- ✅ 🔴 Dependency プロトコルの定義（PinClient / MetadataClient など）

---

## フェーズ 2: データ層（SwiftData）

- ✅ 🔴 `Pin` モデル定義（id / contentType / title / memo / createdAt / isFavorite）
- ✅ 🔴 `ContentType` enum（url / image / video / pdf / text）とペイロード設計
- ✅ 🔴 `Collection` モデル定義（id / name / pins）
- ✅ 🔴 `Tag` モデル定義
- ✅ 🔴 SwiftData `ModelContainer` の DI 設定（`@Dependency`）
- ✅ 🔴 `PinClient` プロトコル + SwiftData 実装（CRUD）

---

## フェーズ 3: ピン管理（MVP コア機能）

- ⬜ 🔴 ピン一覧画面（PinListView / PinListReducer）
  - ⬜ 🔴 グリッド / リスト 切替
  - ⬜ 🔴 種別フィルタバー（URL / 画像 / 動画 / PDF / テキスト / すべて）
- ⬜ 🔴 ピン作成画面（PinCreateView / PinCreateReducer）
  - ⬜ 🔴 種別選択 UI
  - ⬜ 🔴 URL 入力 → メタデータ取得フロー
  - ⬜ 🔴 画像ピッカー（PhotosUI）
  - ⬜ 🟡 動画ピッカー（PhotosUI）
  - ⬜ 🟡 PDF インポート（FileImporter）
  - ⬜ 🔴 テキスト入力
- ⬜ 🔴 ピン詳細画面（PinDetailView / PinDetailReducer）
  - ⬜ 🔴 種別ごとの詳細 UI（URL: WebView / 画像: 全画面 / 動画: AVPlayer / PDF: PDFKit / テキスト: テキスト表示）
- ⬜ 🔴 ピン編集機能（タイトル・メモ・タグ）
- ⬜ 🔴 ピン削除機能（スワイプ削除 / 確認アラート）
- ⬜ 🟡 お気に入り登録・解除
- ⬜ 🟢 並び替え

---

## フェーズ 4: URL メタデータ取得・サムネイル表示

- ⬜ 🔴 `MetadataClient` プロトコル定義（`fetch(url:) async throws -> URLMetadata`）
- ⬜ 🔴 `LPMetadataProvider` を使った実装（og:title / og:image / favicon 取得）
- ⬜ 🔴 取得した og:image をアプリコンテナにキャッシュ保存
- ⬜ 🔴 ピン一覧でのサムネイル表示（非同期・遅延読み込み）
- ⬜ 🔴 メタデータ取得失敗時のフォールバック UI（ファビコン or プレースホルダー）
- ⬜ 🟡 既存 URL ピンのメタデータ再取得（手動リフレッシュ）

---

## フェーズ 5: Share Extension

- ⬜ 🔴 Share Extension ターゲットの追加（Xcode）
- ⬜ 🔴 App Group の設定（ホストアプリと SwiftData ストアを共有）
- ⬜ 🔴 `NSExtensionActivationRule` の設定（`public.url` / `public.image` / `public.movie` / `com.adobe.pdf` / `public.plain-text`）
- ⬜ 🔴 `NSItemProvider` からのコンテンツ種別判定ロジック
- ⬜ 🔴 Share Extension UI（ShareView / ShareReducer）
  - ⬜ 🔴 受け取ったコンテンツのプレビュー表示
  - ⬜ 🔴 タイトル・メモ・コレクション選択フォーム
  - ⬜ 🔴 保存 / キャンセルアクション
- ⬜ 🔴 URL 受信時のメタデータ取得（`MetadataClient` 再利用）
- ⬜ 🔴 画像 / 動画受信時のアプリコンテナへのコピー保存
- ⬜ 🔴 PDF 受信時のアプリコンテナへのコピー保存
- ⬜ 🔴 保存完了後の Extension の閉じ処理

---

## フェーズ 6: コレクション管理

- ⬜ 🔴 コレクション一覧画面
- ⬜ 🔴 コレクション作成・編集・削除
- ⬜ 🔴 コレクションへのピン追加・移動
- ⬜ 🟢 コレクションの共有

---

## フェーズ 7: 検索・タグ

- ⬜ 🟡 検索画面（SearchView / SearchReducer）
- ⬜ 🟡 キーワード検索
- ⬜ 🟡 タグの作成・削除
- ⬜ 🟡 ピンへのタグ付け
- ⬜ 🟡 タグ一覧表示
- ⬜ 🟡 タグによるフィルタ
- ⬜ 🟡 日付・作成順ソート

---

## フェーズ 8: 設定

- ⬜ 🔴 設定画面（SettingsView / SettingsReducer）
- ⬜ 🔴 アプリバージョン・ライセンス表示
- ⬜ 🟡 表示テーマ切り替え（ライト / ダーク / システム）
- ⬜ 🟢 通知設定
- ⬜ 🟢 データのエクスポート

---

## フェーズ 9: テスト・品質

- ⬜ 🔴 PinListReducer のユニットテスト
- ⬜ 🔴 PinCreateReducer のユニットテスト
- ⬜ 🔴 MetadataClient のユニットテスト（モック使用）
- ⬜ 🟡 SearchReducer のユニットテスト
- ⬜ 🟡 SettingsReducer のユニットテスト
- ⬜ 🟡 アクセシビリティ検証（VoiceOver / Dynamic Type）
- ⬜ 🟢 UI テスト

---

## フェーズ 10: リリース準備

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
| 2026-02-19 | 認証フェーズ削除、SwiftData モデルフェーズ追加、URL メタデータ取得フェーズ追加 |
| 2026-02-19 | Share Extension フェーズ追加（フェーズ 5）、2-9 を△→◎に昇格 |
| 2026-02-19 | フェーズ 0（UI プロトタイプ）追加。ホーム画面 UI 実装完了 |
| 2026-02-20 | FAB 展開メニュー実装（タイプ選択・暗転・＋↔×）、PinCreateView 実装（タイプ切り替え・URL/テキスト/ファイル入力・タイトル・メモ）、履歴画面 UI 完了を反映 |
| 2026-02-21 | PinCreateView: 画像/動画（PhotosPicker）・PDF（fileImporter）の実際のファイル選択を実装。タイトル自動補完ロジック追加（URL/テキスト→本文、その他→日時） |
| 2026-02-21 | 検索画面 UI 完了（`.searchable` 標準検索バー・部分一致・マソンリー結果表示）。ピン詳細画面 UI 完了（タイプ別詳細・追加日時/タイプ metaHeader・PinListView / SearchView からモーダル表示）。PinPreviewItem に addedAt: Date 追加 |
| 2026-02-21 | フェーズ 1 完了。AppReducer（State/Action/BindingReducer）実装・AppView（ContentView を TCA 対応にリネーム）・App/ ディレクトリ整備・PinClient / MetadataClient の Dependency 定義（liveValue 空実装・testValue unimplemented）・Pin / ContentType プレースホルダー構造体追加 |
| 2026-02-21 | フェーズ 2 完了。Pin を @Model に移行（urlString / filePath / bodyText ペイロードフィールド + Tag / PinCollection Relationship）・ContentType を別ファイルに分離（Codable/Hashable 対応）・PinCollection / Tag を @Model で新規作成・PinDataStore（@ModelActor）で CRUD 実装・PinClient.liveValue を ModelContainer + PinDataStore ベースの実装に更新 |

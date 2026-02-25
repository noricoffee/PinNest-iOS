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
  - ✅ 🔴 タイトル自動補完（URL/テキストは本文から・画像/動画/PDFはファイル名・空欄時は日時 `yyyy-MM-dd'T'HH:mm:ss`）
- ✅ 🔴 履歴画面 UI（HistoryView）
- ✅ 🔴 ピン詳細画面 UI（PinDetailView）
  - ✅ 🔴 タイプ別詳細表示（URL / 画像 / 動画 / PDF / テキスト）
  - ✅ 🔴 追加日時・コンテンツタイプ表示（metaHeader）
  - ✅ 🔴 URL タイプ: サムネイル・ドメイン・「Safari で開く」ボタン
  - ✅ 🔴 テキストタイプ: 全文表示
  - ✅ 🔴 PinListView / SearchView のカードタップ → モーダル表示
- ⬜ 🟡 コレクション詳細画面 UI（CollectionDetailView）
- ✅ 🟡 検索画面 UI（SearchView）
  - ✅ 🟡 標準検索バー（`.searchable`）
  - ✅ 🟡 空状態 / 結果なし状態（ContentUnavailableView）
  - ⬜ 🟡 実データ検索・結果グリッド表示（フェーズ 7 で対応）
- ⬜ 🟡 設定画面 UI（SettingsView）

> ⚠️ このフェーズは UI の見た目確認用。TCA Reducer・SwiftData は未実装。確認完了後に各フェーズで本実装を行う。

---

## フェーズ 1: 環境構築・基盤

- ✅ 🔴 プロジェクトセットアップ（Xcode / Swift Package Manager）
- ✅ 🔴 TCA パッケージの導入
- ✅ 🔴 AppReducer / ルート NavigationStack の実装
- ✅ 🔴 ディレクトリ構成の整備（App / Features / Shared）
- ✅ 🔴 Dependency プロトコルの定義（PinClient / MetadataClient など）
- ✅ 🟡 Firebase 導入（Crashlytics / Analytics / Performance）
  - ✅ 🟡 Firebase iOS SDK を SPM で追加（FirebaseCrashlytics / FirebaseAnalytics / FirebasePerformance）
  - ✅ 🟡 GoogleService-Info.plist 配置
  - ✅ 🟡 AppDelegate + UIApplicationDelegateAdaptor で FirebaseApp.configure() 初期化
  - ✅ 🟡 Crashlytics dSYM アップロード Run Script Build Phase 設定（Xcode 手動）
  - ✅ 🟡 AnalyticsClient / CrashlyticsClient を TCA Dependency として実装
  - ✅ 🟡 主要 Reducer にイベント送信・non-fatal エラー記録を追加（15 イベント）

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

- ✅ 🔴 ピン一覧画面（PinListView / PinListReducer）
  - ✅ 🔴 種別フィルタバー（URL / 画像 / 動画 / PDF / テキスト / すべて）
  - ✅ 🔴 ピン一覧取得（SwiftData 経由）・空状態表示
  - ✅ 🔴 カードタップ → 詳細シート表示
- ✅ 🔴 ピン作成画面（PinCreateView / PinCreateReducer）
  - ✅ 🔴 種別選択 UI（pill チップ）
  - ⬜ 🔴 URL 入力 → メタデータ取得フロー（フェーズ 4 で対応）
  - ✅ 🔴 URL 入力 + 保存（SwiftData）
  - ✅ 🔴 画像ピッカー（PhotosUI）
  - ✅ 🟡 動画ピッカー（PhotosUI）
  - ✅ 🟡 PDF インポート（FileImporter）
  - ✅ 🔴 テキスト入力 + 保存
  - ✅ 🔴 タイトル自動補完（URL/テキスト→本文、画像/動画/PDF→ファイル名、その他→日時）
  - ✅ 🔴 作成 / 編集モード切り替え（Mode: .create / .edit）
- ✅ 🔴 ピン詳細画面（PinDetailView / PinDetailReducer）
  - ✅ 🔴 種別ごとの詳細 UI（URL / 画像 / 動画 / PDF / テキスト）
  - ✅ 🔴 URL タイプ: Safari で開く（`openURL` Dependency）
- ✅ 🔴 ピン編集機能（PinCreateReducer .edit モードで対応）
- ✅ 🔴 ピン削除機能（確認アラート → SwiftData 削除）
- ✅ 🟡 お気に入り登録・解除（ハートボタン・SwiftData 更新）
- ⬜ 🟢 並び替え

---

## フェーズ 4: URL メタデータ取得・サムネイル表示

- ✅ 🔴 `MetadataClient` プロトコル定義（`fetch(url:) async throws -> URLMetadata`）
- ✅ 🔴 `LPMetadataProvider` を使った実装（og:title / og:image / favicon 取得）
- ✅ 🔴 取得した og:image をアプリコンテナにキャッシュ保存（`ThumbnailCache` / `cachesDirectory/thumbnails/`）
- ✅ 🔴 ピン一覧でのサムネイル表示（`PinCardView` で `pin.filePath` から `UIImage` を読み込み）
- ✅ 🔴 メタデータ取得失敗時のフォールバック UI（カラー背景 + globe アイコン）
- ✅ 🟡 既存 URL ピンのメタデータ再取得（手動リフレッシュ：PinDetailView の「サムネイルを再取得」ボタン）

---

## フェーズ 5: Share Extension

- 🔄 🔴 Share Extension ターゲットの追加（Xcode）← コード生成済み。Xcode での手動設定が必要
- 🔄 🔴 App Group の設定（ホストアプリと SwiftData ストアを共有）← entitlements 生成済み。Xcode での Signing & Capabilities 設定が必要
- ✅ 🔴 `NSExtensionActivationRule` の設定（`public.url` / `public.image` / `public.movie` / `com.adobe.pdf` / `public.plain-text`）
- ✅ 🔴 `NSItemProvider` からのコンテンツ種別判定ロジック
- ✅ 🔴 Share Extension UI（ShareView / ShareReducer）
  - ✅ 🔴 受け取ったコンテンツのプレビュー表示
  - ✅ 🔴 タイトル・メモ入力フォーム
  - ✅ 🔴 保存 / キャンセルアクション
- ✅ 🔴 URL 受信時のメタデータ取得（`MetadataClient` 再利用）
- ✅ 🔴 画像 / 動画受信時のアプリコンテナへのコピー保存
- ✅ 🔴 PDF 受信時のアプリコンテナへのコピー保存
- ✅ 🔴 保存完了後の Extension の閉じ処理

---

## フェーズ 5.5: Apple Developer / Xcode 設定（Share Extension 有効化）

> フェーズ 5 で生成したコードを実際に動かすために必要な Xcode・Apple Developer 側の設定。後回し可。

- ⬜ 🔴 Apple Developer Portal で App Group `group.com.yoshidanoriyuki.pinnest` を作成・登録
- ⬜ 🔴 Xcode で Share Extension ターゲットを追加
  - File > New > Target > Share Extension、Product Name: `pinNestShareExtension`
- ⬜ 🔴 Extension ターゲットのソースファイル設定
  - `pinNestShareExtension/` 配下の Swift 3 ファイルを Extension ターゲットに追加
  - `pinNest/Shared/` 配下の共有コード（PinClient, PinDataStore, MetadataClient, ThumbnailCache, AppGroupContainer, Pin, ContentType, PinCollection, Tag）を Extension ターゲットのメンバーに追加
- ⬜ 🔴 両ターゲットに App Groups 設定
  - Signing & Capabilities > App Groups > `group.com.yoshidanoriyuki.pinnest`（pinNest・Extension 両方）
- ⬜ 🔴 Code Signing Entitlements の設定
  - pinNest: `pinNest/pinNest.entitlements`
  - pinNestShareExtension: `pinNestShareExtension/pinNestShareExtension.entitlements`
- ⬜ 🔴 ComposableArchitecture を Extension ターゲットにリンク（Frameworks and Libraries）
- ⬜ 🔴 Extension の Info.plist ファイルを Build Settings で指定（`pinNestShareExtension/Info.plist`）
- ⬜ 🟡 実機 / Simulator で動作確認（Safari URL 共有・写真共有・PDF 共有）

---

## フェーズ 6: コレクション管理

> ⛔ スコープ外。シンプルさを優先し、ピン単体管理のみとする。PinCollection モデルは削除済み。

- ~~⬜ 🔴 コレクション一覧画面~~
- ~~⬜ 🔴 コレクション作成・編集・削除~~
- ~~⬜ 🔴 コレクションへのピン追加・移動~~
- ~~⬜ 🟢 コレクションの共有~~

---

## フェーズ 7: 検索・タグ

- ✅ 🟡 検索画面（SearchView / SearchReducer）
- ✅ 🟡 キーワード検索（タイトル・メモ・本文・URL 部分一致、300ms デバウンス）
- ✅ 🟡 タグの作成・削除（TagPickerView から新規作成）
- ✅ 🟡 ピンへのタグ付け（PinDetailView タグセクション）
- ✅ 🟡 タグ一覧表示（SearchView タグフィルターバー）
- ✅ 🟡 タグによるフィルタ（SearchReducer）
- ✅ 🟡 日付・作成順ソート（SearchView ソートメニュー）

---

## フェーズ 8: 設定

- ✅ 🔴 設定画面（SettingsView / SettingsReducer）
- ✅ 🔴 アプリバージョン・ライセンス表示
- ✅ 🟡 表示テーマ切り替え（ライト / ダーク / システム）
- ⬜ 🟢 データのエクスポート

---

## フェーズ 9: テスト・品質

- ✅ 🔴 PinListReducer のユニットテスト
- ✅ 🔴 PinCreateReducer のユニットテスト
- ✅ 🔴 MetadataClient のユニットテスト（モック使用）
- ✅ 🟡 SearchReducer のユニットテスト
- ✅ 🟡 SettingsReducer のユニットテスト
- ⬜ 🟡 アクセシビリティ検証（VoiceOver / Dynamic Type）
- ⬜ 🟢 UI テスト

---

## フェーズ 10: リリース準備

- ✅ 🔴 App Icon / スプラッシュ画面
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
| 2026-02-23 | Swift 6 移行完了（SWIFT_VERSION=6.0 / SWIFT_STRICT_CONCURRENCY=complete）。SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor を削除（TCA Reducer と DI 非互換のため）。@Model クラスに @unchecked Sendable 付与 |
| 2026-02-23 | フェーズ 3 完了。ContentType に displayColor/iconName/label を追加・PinContentType を typealias に統合・PinListReducer / PinDetailReducer / PinCreateReducer 作成・AppReducer に pinList/pinCreate state 統合・全 View を TCA Store 接続に更新（PinListView / PinDetailView / PinCreateView）。お気に入り・削除アラート・編集・Safari 開く を実装 |
| 2026-02-23 | クラッシュ修正。`store.scope(state: \.pinCreate!, …)` の force-unwrap に起因する ScopedCore.state.getter クラッシュを修正。AppReducer / PinListReducer を `@Presents` + `body:` + `ifLet` パターンに変更し、View の sheet を `sheet(item: $store.scope(state:action:))` に差し替え |
| 2026-02-23 | フェーズ 4 完了。MetadataClient を LPMetadataProvider で実装（og:title / og:image / favicon 取得）。ThumbnailCache を新規作成（cachesDirectory/thumbnails/ に JPEG 保存）。NewPin に id フィールドを追加。PinCreateReducer の URL 保存フローにメタデータ取得を組み込み。PinCardView / PinDetailView でサムネイル表示。PinDetailReducer / PinDetailView に手動再取得ボタンを追加 |
| 2026-02-24 | フェーズ 5 コード実装。AppGroupContainer（共有コンテナ管理）新規作成。PinClient / ThumbnailCache を App Group 対応に修正。ShareReducer / ShareView / ShareViewController を pinNestShareExtension/ に作成。Info.plist（NSExtensionActivationRule）・entitlements（App Group）生成。Xcode でのターゲット追加・App Group 設定は手動対応が必要 |
| 2026-02-24 | フェーズ 7 完了。TagItem / PinSortOrder 値型追加。PinDataStore にタグ CRUD・検索メソッド追加。SearchReducer / SearchView（キーワード検索・タグフィルター・ソート・マソンリー結果）実装。TagPickerReducer / TagPickerView（タグ選択・新規作成シート）新規作成。PinDetailReducer を body パターンに移行しタグ管理アクション追加。PinDetailView にタグセクション追加。AppReducer / AppView に search state 統合 |
| 2026-02-24 | フェーズ 8 完了（🔴🟡）。ColorSchemePreference enum 追加。SettingsReducer / SettingsView 新規作成（テーマ切り替え・バージョン表示・ライセンス）。AppReducer に colorSchemePreference state・settings @Presents 追加。AppView に設定ボタン（glassEffect circle）・settings sheet・preferredColorScheme 適用 |
| 2026-02-24 | フェーズ 9 完了（🔴🟡）。pinNestTests ターゲットを xcodeproj に追加（スタンドアローン方式：BUNDLE_LOADER なし、pinNest/ ソースを直接コンパイル）。PinListReducerTests / PinCreateReducerTests / MetadataClientTests / SearchReducerTests / SettingsReducerTests を @Suite + @Test + TestStore で実装。合計 55 テスト全パス |
| 2026-02-25 | Firebase 導入（Crashlytics / Analytics）。FirebaseCrashlytics / FirebaseAnalytics を SPM で追加。AppDelegate クラスを作成し UIApplicationDelegateAdaptor 経由で FirebaseApp.configure() を didFinishLaunchingWithOptions で呼び出すよう実装。dSYM アップロード Build Phase のみ Xcode 手動設定が残り |
| 2026-02-25 | 履歴画面をリアルデータ対応に移行。HistoryReducer（onAppear/refresh/pinTapped/detail）新規作成。HistoryView をダミーデータ（HistoryEntry.samples）から TCA Store ベースに更新。AppReducer に history state・action・Scope を追加。ピン保存後に history.refresh も発火。履歴からの詳細表示・編集ボタン対応 |
| 2026-02-25 | 画像・動画のタイトル自動補完をファイル名ベースに変更。`FileRepresentation(importedContentType:)` 経由で元ファイル名を取得（Photos 権限不要）。`ImageFileTransferable` / `VideoFileTransferable` を PinCreateView 内に追加。`effectiveTitle` / `titlePlaceholder` を image/video/pdf でファイル名優先に更新 |

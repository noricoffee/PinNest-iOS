# App Store Connect 登録手順

> Bundle ID: `com.noricoffee.pinNest` / 開発チームID: `HL5AQP4983`

---

## ステップ 1: App Store Connect でアプリを新規登録

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) にログイン
2. 「マイ App」→「+」→「新規 App」
3. 以下を入力：

| 項目 | 値 |
|------|-----|
| プラットフォーム | iOS |
| 名前 | pinNest |
| プライマリ言語 | 日本語 |
| Bundle ID | `com.noricoffee.pinNest`（ドロップダウンから選択） |
| SKU | `pinnest-v1`（任意の一意な文字列） |
| ユーザーアクセス | フルアクセス |

> Bundle ID がドロップダウンに表示されない場合は、Apple Developer Portal で App ID を先に作成してください。

---

## ステップ 2: App 情報の入力

「App 情報」タブで以下を設定：

- **カテゴリ**: ユーティリティ（プライマリ）
- **コンテンツの権利**: 「自作のコンテンツを使用しています」を選択
- **年齢制限**: 「4+」（ゲーミング / 成人コンテンツなし）

---

## ステップ 3: バージョン情報（1.0）の入力

「iOS App 1.0 準備中」タブで以下を入力：

### App Store 掲載テキスト（`docs/app-store-metadata.md` を参照）

| 項目 | 値 |
|------|-----|
| 説明 | `docs/app-store-metadata.md` の「説明文」をコピー |
| キーワード | `docs/app-store-metadata.md` の「キーワード」をコピー |
| プロモーションテキスト | `docs/app-store-metadata.md` の「プロモーションテキスト」をコピー |
| サポート URL | `https://github.com/noricoffee/PinNest-iOS` |
| マーケティング URL | （空欄でも可） |
| プライバシーポリシー URL | `https://noricoffee.github.io/PinNest-iOS/privacy-policy` |

### スクリーンショット

- Xcode Simulator（iPhone 16 Pro Max など）で実機の画面を起動
- `Command + S` でスクリーンショット撮影
- 必要サイズ: **1320 × 2868 px**（6.9インチ、必須）
- 最低1枚、推奨5〜8枚

### ビルドの選択（後で設定）

「ビルドを追加」はステップ 5 でアーカイブ後に設定します。

---

## ステップ 4: プライバシー情報の入力

「App のプライバシー」タブ：

- **データを収集しない** → 選択
  - ただし Firebase（Analytics / Crashlytics）を使用するため以下を申告：

| データの種類 | 用途 | トラッキングに使用 | 第三者と共有 |
|-------------|------|-------------------|------------|
| クラッシュデータ | アプリの改善 | いいえ | Firebase（Google） |
| パフォーマンスデータ | アプリの改善 | いいえ | Firebase（Google） |
| 製品インタラクション（使用状況） | アプリの改善 | いいえ | Firebase（Google） |

---

## ステップ 5: Xcode でアーカイブ → App Store Connect にアップロード

```
Xcode → Product → Archive
```

1. スキームを `pinNest`、実行先を「Any iOS Device (arm64)」に設定
2. `Product → Archive` を実行（Release ビルドでアーカイブ）
3. Organizer が開いたら「Distribute App」→「App Store Connect」→「Upload」
4. 証明書・プロビジョニングプロファイルを確認して続行
5. アップロード完了後、App Store Connect の「TestFlight」タブにビルドが表示される

> App Group の Entitlements が正しく設定されていないとビルドが失敗します。
> `pinNest/pinNest.entitlements` と `shareExtension/shareExtension.entitlements` に
> `com.apple.security.application-groups: [group.com.yoshidanoriyuki.pinnest]` が含まれていることを確認。

---

## ステップ 6: TestFlight でテスト配布

1. App Store Connect → TestFlight → アップロードされたビルドを選択
2. 「内部テスト」グループにビルドを追加
3. 「外部テスト」に追加する場合は Apple の簡易審査（Beta App Review）が必要

---

## ステップ 7: App Store 審査申請

1. バージョン情報画面で「審査のために提出」をクリック
2. 追加の質問に回答：
   - 「デモアカウントは必要か？」→ いいえ（ログイン機能なし）
   - 「App の権利について」→ 自作コンテンツのみ使用
3. 送信後、審査待ちキュー（通常 1〜3 日）

---

## チェックリスト

- [ ] App Store Connect でアプリ新規登録
- [ ] アプリ情報（カテゴリ・年齢制限）入力
- [ ] バージョン 1.0 の説明文・キーワード入力
- [ ] プライバシーポリシー URL 入力（`https://noricoffee.github.io/PinNest-iOS/privacy-policy`）
- [ ] スクリーンショット撮影・アップロード（6.9インチ必須）
- [ ] プライバシー情報（Firebase データ収集）申告
- [ ] Xcode でアーカイブ → App Store Connect にアップロード
- [ ] TestFlight で動作確認
- [ ] 審査申請

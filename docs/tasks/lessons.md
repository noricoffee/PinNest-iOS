# Lessons Learned

## 2026-03-11: SwiftUI `.contextMenu` のタイプ別メニュー遅延問題

### 症状
- 長押しメニューで共通項目のみが先に表示され、タイプ固有項目が遅れて表示される
- SwiftUI の `.contextMenu` 内の描画が遅延する

### 試したが効果がなかったアプローチ
1. `if`/`switch` を `.contextMenu` の外に出す
2. `ForEach` + `PinMenuAction` 配列で事前構築
3. `contentType` を plain value で渡す
4. UIKit `UIContextMenuInteraction` で `.contextMenu` をバイパス → メニュー自体が表示されなくなった

### 反省点
- **同じアプローチの変形を繰り返した**: SwiftUI `.contextMenu` の中身を変え続けたが根本原因の検証がなかった
- **ビルド成功 ≠ 修正完了**: UI の挙動バグはシミュレータ実行でしか確認できない
- **再計画しなかった**: 2回失敗した時点で立ち止まるべきだった

### ルール化
- **3回同じ系統のアプローチで失敗 → 必ず Plan Mode に入り根本原因を再調査**
- **UI 挙動バグの修正は「シミュレータでの動作確認」を完了条件にする**
- **UIKit ↔ SwiftUI の混在は小さな PoC で動作確認してから本実装に組み込む**
- **修正前に再現条件を明確にする**（どの画面、どの操作、どういう状態のとき）

### 未解決
- `.contextMenu` のタイプ固有メニュー遅延の根本原因は未特定
- 仮説: SwiftData `@Model` の `contentType` プロパティアクセスが遅延している可能性
- 仮説: SwiftUI が `ForEach` の動的コンテンツを `UIDeferredMenuElement` に変換している可能性
- 次のアプローチ: まず根本原因を特定するためのデバッグ（`os_log` / `os_signpost` でタイミング計測）

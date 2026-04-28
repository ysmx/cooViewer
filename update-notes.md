# cooViewer 更新履歴

## macOS Sequoia 対応・Universal Binary 化

- フルスクリーン時に画面上端へ細いグレー帯が出る問題を修正
  - 擬似フルスクリーン時に `NSBorderlessWindowMask` へ切り替えるよう変更
  - 旧実装の `+22` ピクセル補正を廃止し、フレーム計算を整理
- `arm64` / `x86_64` の Universal Binary としてビルド可能に
- 同梱フレームワーク（XADMaster, UniversalDetector）も Universal Binary 化

## 1.3 系

- **1.3** — バージョンを 1.3 に更新
- **1.3.1** — Finder からファイルを開いた際、フルスクリーン中の cooViewer が前面に出ない問題を修正
- **1.3.2–1.3.3** — Preferences ウィンドウのレイアウト調整
- **1.3.4** — ソートに降順指定を追加
- **1.3.5–1.3.6** — フィルタパネルのレイアウト修正、`IKFilterUIView` を復帰
- **1.3.7** — 複数ディスプレイ環境で、サブディスプレイ背景をメイン表示と同期するオプションを追加
- **1.3.8** — フルスクリーン中の Cmd+Tab / App Switcher 周りの問題を修正
- **1.3.9**
  - サブディスプレイの黒カバー処理を見直し（`CGDisplayCapture` / `CGShieldingWindowLevel` を廃止し、通常の borderless `NSWindow` で覆う方式に変更）
  - App Switcher の横取りを廃止し、macOS に処理を委ねるよう変更
  - フィルター追加パネルがフィルターパネルに重ならないよう自動配置
  - カスタム書類アイコン（`coo_*.icns`）を廃止し、macOS の自動合成アイコンに移行
  - 最低動作環境を macOS 10.14 Mojave 以降に引き上げ

## 1.4.0

- シャッフルアルゴリズムを Fisher-Yates 法に変更（偏りを解消）
- シャッフル ON/OFF 切り替え時のクラッシュを修正
- シャッフル OFF 時に直前のソートモードと表示位置を復元
- シャッフル ON 中はソートメニューをグレーアウト
- シャッフルはファイルを開くたびに OFF から開始（設定に保存しない）
- フルスクリーン時にシャッフル切り替えで Dock・メニューバーが残る問題を修正
- カーソルタイマー解放時のクラッシュを修正
- 対応フォーマットを追加：HEIC/HEIF, WebP, AVIF, PSD, カメラ RAW（DNG, CR2/CR3, NEF, ARW, RAF, RW2, ORF, PEF など）

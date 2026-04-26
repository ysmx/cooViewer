# cooViewer 更新履歴・技術メモ

このメモは、2026-04-14 の macOS Sequoia 対応と universal binary 化から始まった、更新版 cooViewer の主な修正内容を整理したものです。

## 2026-04-14: macOS Sequoia 対応と universal 化

### 目的

- macOS Sequoia でフルスクリーン時に画面上端へ細いグレー帯が出る問題を修正する
- `cooViewer.app` を `arm64` / `x86_64` の universal binary としてビルド可能にする

### 主な変更

- 擬似フルスクリーン時に `NSBorderlessWindowMask` へ切り替えるよう変更
- 旧実装の `+22` ピクセル補正を廃止
- フルスクリーン用フレーム計算を `fullscreenFrame` へ整理
- 通常表示へ戻る際に元の style mask を復元
- borderless 化しても入力を失わないよう `canBecomeKeyWindow` / `canBecomeMainWindow` を追加
- `XADMaster.framework` と `UniversalDetector.framework` を universal binary 化

### 確認結果

- `cooViewer.app` は `x86_64 arm64`
- 同梱 `XADMaster.framework` は `x86_64 arm64`
- 同梱 `UniversalDetector.framework` は `x86_64 arm64`
- `arm64` ネイティブ起動と `arch -x86_64` による Rosetta 起動の両方で即時クラッシュなし

## 1.3 系の更新

### 1.3

- アプリバージョンを `1.3` に更新

### 1.3.1

- Finder からファイルを開いたとき、フルスクリーン表示中の cooViewer が前面に出ない場合がある問題を修正

### 1.3.2 - 1.3.3

- Preferences ウィンドウのレイアウトを調整

### 1.3.4

- ソートに降順指定を追加

### 1.3.5 - 1.3.6

- フィルタパネルのレイアウトを修正
- `IKFilterUIView` を復帰
- フィルタ選択 UI の行ラベル位置を調整

### 1.3.7

- 複数ディスプレイ環境向けに、サブディスプレイ背景をメイン表示と同期するオプションを追加

### 1.3.8

- フルスクリーン中の Cmd+Tab / App Switcher 周りの問題を修正

### 1.3.9

- IINA の実装を参考に、サブディスプレイの黒カバー処理を見直し
- `CGDisplayCapture` / `CGShieldingWindowLevel()` によるディスプレイ捕捉を廃止
- サブディスプレイは通常の borderless `NSWindow` で黒く覆う方式に変更
- Cmd+Tab の横取りと合成 `CGEvent` 再投入を削除し、App Switcher は macOS に処理させるよう変更
- サブディスプレイ用カバーウィンドウの座標を対象スクリーン内座標に修正
- cooViewer が非アクティブになるタイミングでサブディスプレイの黒カバーを消すよう修正
- Finder からファイルを開いた際の前面化リトライ処理を調整
- フィルター追加パネルがメインのフィルターパネルに重ならないよう、ボタンに近い空き位置へ自動配置するよう修正

## ビルド時メモ

- 現行 Xcode 環境では、コマンドラインビルド時に `MACOSX_DEPLOYMENT_TARGET=10.13` を指定して確認している
- `./script/build_and_run.sh` で既存プロセス停止、ビルド、起動まで行う

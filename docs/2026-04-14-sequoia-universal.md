# 2026-04-14 修正メモ

## 目的

- macOS Sequoia でフルスクリーン時に画面上端へ細いグレー帯が出る問題を修正する
- `cooViewer.app` を `arm64` / `x86_64` の universal binary としてビルド可能にする

## 変更内容

### 1. フルスクリーン表示の修正

対象:

- `CustomWindow.h`
- `CustomWindow.m`

対応:

- 擬似フルスクリーン時に `NSBorderlessWindowMask` へ切り替えるよう変更
- 旧実装の `+22` ピクセル補正を廃止
- フルスクリーン用フレーム計算を `fullscreenFrame` へ整理
- 通常表示へ戻る際に元の style mask を復元
- borderless 化しても入力を失わないよう `canBecomeKeyWindow` / `canBecomeMainWindow` を追加

意図:

- 古い titled window ベースの擬似フルスクリーン実装では、Sequoia 上でタイトルバー相当領域が完全に隠れず、上端にグレー帯が残っていた
- フルスクリーン時だけ borderless にすることで、上端のシステム背景が露出しないようにした

### 2. Universal 化

対象:

- `XADMaster.framework`
- `UniversalDetector.framework`

対応:

- `The Unarchiver` のソースから `XADMaster` と `UniversalDetector` を取得
- それぞれ `x86_64` / `arm64` で別ビルド
- `lipo -create` で fat binary 化
- このプロジェクト同梱の framework を universal binary に差し替え
- その状態で `cooViewer.app` を `ARCHS='arm64 x86_64'` で再ビルド

確認結果:

- `build/Development/cooViewer.app/Contents/MacOS/cooViewer` は `x86_64 arm64`
- 同梱 `XADMaster.framework/XADMaster` は `x86_64 arm64`
- 同梱 `UniversalDetector.framework/UniversalDetector` は `x86_64 arm64`
- `arm64` ネイティブ起動と `arch -x86_64` による Rosetta 起動の両方で即時クラッシュなし

## ビルド時メモ

- 現行 Xcode 環境では元の `MACOSX_DEPLOYMENT_TARGET=10.8` のままだと `libarclite` 周りでビルドしづらいため、今回の確認ではコマンドラインから `MACOSX_DEPLOYMENT_TARGET=10.13` を指定した
- これは今回のビルド確認用の上書きであり、project 設定自体は変更していない

## 備考

- 旧 x86_64-only framework の退避コピーは `/tmp/cooviewer-universal` に作成してある

# cooViewer

cooViewer は macOS 向けの画像ビューアです。

オリジナル版:
https://coo-ona.github.io/cooViewer/

## 開発・ビルド環境

現在の更新版は、macOS Sequoia 以降および Apple Silicon / Intel Mac の両対応を目的として保守しています。

**動作環境: macOS 10.14 Mojave 以降**

## インストール

[Homebrew](https://brew.sh/) を使ってインストールできます。

```bash
brew install --cask ysmx/cooviewer/cooviewer
```

または：

```bash
brew tap ysmx/cooviewer
brew install --cask cooviewer
```

## 操作方法
https://coo-ona.github.io/cooViewer/manual.html

## 更新履歴・技術メモ

macOS Sequoia 対応、universal binary 化、Finder 起動時の前面化、複数ディスプレイ環境でのフルスクリーン表示、Cmd+Tab / App Switcher 周り、フィルター追加パネルの配置修正については以下にまとめています。

[docs/update-notes.md](docs/update-notes.md)

## アンインストール
・アプリ本体<br>
・/Users/(ユーザー名)/ライブラリ/Preferences/jp.coo.cooViewer.plist<br>
を消してください

## 著作権、免責等
cooViewerはMITライセンスです。
ライセンスについては添付のLicence.txtを参照してください。

このソフトウェアはXAD library system ( http://sourceforge.net/projects/libxad/ ) を使用しています。<br>
ライセンスについては添付のLicence_xad.txtを参照してください。

このソフトウェアはRemote Control Wrapper ( http://www.martinkahr.com/source-code/ ) を使用しています。<br>
ライセンスについては添付のLicence_RemoteControlWrapper.txtを参照してください。

アプリアイコンは [macOS App Icons](https://macosicons.com/) に掲載されている vladlucha 氏のアイコンを使用しています。<br>
https://macosicons.com/?icon=XsWGbR0OuK

書類アイコンは macOS の自動合成（アプリアイコン＋拡張子バッジ）を使用しています。

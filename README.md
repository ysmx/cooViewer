# cooViewer

cooViewer は macOS 向けの画像ビューアです。

オリジナル版:
https://coo-ona.github.io/cooViewer/

## 動作環境

macOS 10.14 Mojave 以降

## 主な改善点

#### 新しいmacOSへの対応
- Apple Silicon / Intel 両対応の Universal Binary 化
- macOS Sequoia 以降でのフルスクリーン表示、複数ディスプレイ環境での表示を改善

#### 対応フォーマットの追加
- HEIC/HEIF, WebP, AVIF, PSD に対応
- 主要なカメラ RAW 形式に対応

#### 大量ファイル環境での安定性向上
- 大量のフォルダや CBZ/CBR がある環境でも固まりにくいよう改善
- 壊れたアーカイブや読めないファイルが混ざっていても、操作不能になりにくいよう調整

#### 閲覧操作の改善
- シャッフル表示の偏りや、切り替え時の不具合を修正
- ソートに降順を追加
- サムネイル一覧からアーカイブを開く（Return / Enter）/ 戻る（Backspace）操作を追加
- ページ数表示とページバーの見た目・配置設定を変更

#### 日本語ファイル名への対応
- 濁点・半濁点を含むファイル名でも、履歴や前回のページ位置を復元しやすいよう改善

#### インストール方法の追加
- Homebrew Cask からインストール可能に

#### アイコンの変更
- アプリと書類のアイコンを変更

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

## 対応フォーマット

#### アーカイブ
ZIP, RAR, CBZ, CBR, 7Z, TAR, GZ, BZ2, XZ, LZH/LHA, CAB など

#### 画像
JPEG, PNG, GIF, BMP, TIFF, PDF, HEIC/HEIF, WebP, AVIF, PSD など

#### RAW形式
DNG, CR2/CR3, NEF/NRW, ARW/SR2, RAF, RW2, ORF, PEF など

## 操作方法
https://coo-ona.github.io/cooViewer/manual.html

## 更新履歴

詳細は以下にまとめています。

[update-notes.md](update-notes.md)

## アンインストール
・アプリ本体<br>
・/Users/(ユーザー名)/ライブラリ/Preferences/jp.coo.cooViewer.plist<br>
を消してください

## 著作権、免責等
cooViewerはMITライセンスです。
ライセンスについては添付のLicence.txtを参照してください。
オリジナルはcoo氏によって作成されました。

このソフトウェアはXAD library system ( http://sourceforge.net/projects/libxad/ ) を使用しています。<br>
ライセンスについては添付のLicence_xad.txtを参照してください。

このソフトウェアはRemote Control Wrapper ( http://www.martinkahr.com/source-code/ ) を使用しています。<br>
ライセンスについては添付のLicence_RemoteControlWrapper.txtを参照してください。

アプリアイコンは [macOS App Icons](https://macosicons.com/) に掲載されている vladlucha 氏のアイコンを使用しています。<br>
https://macosicons.com/?icon=XsWGbR0OuK

書類アイコンは macOS の自動合成（アプリアイコン＋拡張子バッジ）を使用しています。

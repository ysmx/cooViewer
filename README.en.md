# cooViewer

🇯🇵 [日本語](README.md) | 🇺🇸 English

cooViewer is an image viewer for macOS.

Original version:
https://coo-ona.github.io/cooViewer/

## Requirements

macOS 10.14 Mojave or later

## Key improvements

#### Support for newer macOS
- Universal Binary supporting both Apple Silicon and Intel
- Improved full-screen display on macOS Sequoia and later, and improved display in multi-display setups

#### Additional supported formats
- Support for HEIC/HEIF, WebP, AVIF, PSD
- Support for major camera RAW formats

#### Improved stability with large numbers of files
- Improved responsiveness in environments with a large number of folders or CBZ/CBR files
- Adjusted so the app is less likely to become unresponsive when corrupted or unreadable archives are present

#### Improved viewing operations
- Fixed bias in shuffle display and issues when toggling it
- Added descending sort order
- Added opening an archive from the thumbnail list (Return / Enter) and going back (Backspace)
- Changed the appearance and placement settings for the page number display and page bar

#### Support for Japanese filenames
- Improved restoration of history and the last-viewed page position for filenames containing dakuten/handakuten (Japanese diacritical marks)

#### Additional install method
- Can now be installed via Homebrew Cask

#### Icon change
- Changed the app and document icons

## Installation

You can install it using [Homebrew](https://brew.sh/).

```bash
brew install --cask ysmx/cooviewer/cooviewer
```

or:

```bash
brew tap ysmx/cooviewer
brew install --cask cooviewer
```

## Supported formats

#### Archives
ZIP, RAR, CBZ, CBR, 7Z, TAR, GZ, BZ2, XZ, LZH/LHA, CAB, etc.

#### Images
JPEG, PNG, GIF, BMP, TIFF, PDF, HEIC/HEIF, WebP, AVIF, PSD, etc.

#### RAW formats
DNG, CR2/CR3, NEF/NRW, ARW/SR2, RAF, RW2, ORF, PEF, etc.

## Usage
https://coo-ona.github.io/cooViewer/manual.html

## Changelog

See the details here.

[update-notes.md](update-notes.md)

## Uninstallation
Please delete:<br>
・The app itself<br>
・/Users/(your username)/Library/Preferences/jp.coo.cooViewer.plist<br>

## Copyright, disclaimer, etc.
cooViewer is licensed under the MIT License.
Please refer to the attached Licence.txt for license details.
The original was created by coo.

This software uses the XAD library system ( http://sourceforge.net/projects/libxad/ ).<br>
Please refer to the attached Licence_xad.txt for license details.

This software uses Remote Control Wrapper ( http://www.martinkahr.com/source-code/ ).<br>
Please refer to the attached Licence_RemoteControlWrapper.txt for license details.

The app icon uses an icon by vladlucha, published on [macOS App Icons](https://macosicons.com/).<br>
https://macosicons.com/?icon=XsWGbR0OuK

The document icon uses macOS's automatic icon composition (app icon + extension badge).

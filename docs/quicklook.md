# Quick Look extensions (development)

cooViewer embeds two independent macOS app extensions:

- `jp.coo.cooViewer.thumbnail`: Finder thumbnail, using `QLThumbnailProvider`.
- `jp.coo.cooViewer.preview`: view-based Quick Look preview with an NSImageView and a right-hand vertical thumbnail sidebar, limited to twenty-five pages. No PDF is generated.

Both support image-containing archives handled by the app’s existing XADMaster. The accepted extensions are **CBZ, CBR, ZIP, RAR, 7z, LHA/LZH, SIT/SITX, HQX, BIN/MACBIN, GZ/GZIP, TGZ/TAR-GZ, BZ/BZ2/BZIP2, TBZ/TBZ2, XZ/TXZ, TAR/GTAR, Z/TAZ/TAR-Z, LZMA, XAR, ACE, ARJ, ARC/PAK/SPK, ZOO, LBR/LQR/LZR, CAB, ALZ, DD, CPT, PIT, NOW, SEA, CPIO/CPGZ, PAX, HA, NSA/SAR and JAR**. Individual compression variants still depend on XADMaster and the limits below. Archives without images return an error rather than a fabricated thumbnail. Ordinary images and PDF retain their OS providers; folders/CVBDL, disk/ROM images, EXE and split volumes are not registered. CB7/CBT aliases are not claimed because the app does not declare them. Multipart archives are outside the supported scope. The main viewer's existing format support remains unchanged. The current local trial displays up to twenty-five naturally ordered candidates starting at the first readable image, with no final-page selection. The Finder thumbnail provider remains independent.

## Reader and limits

Both targets compile the same UI-independent `Sources/QuickLook/Shared/COComicArchive` reader and link the project's existing XADMaster and UniversalDetector frameworks. No Simple Comic implementation or binaries are included. Each extension embeds its own framework copies because this project's framework install names use `@executable_path/../Frameworks`.

Archive metadata is enumerated and naturally sorted without decoding the image entries. The first readable image is decoded at a longest-edge limit of 1600 and displayed immediately. The right-hand sidebar then generates small (160-pixel) thumbnails for visible rows only on a separate reader queue. Only a selected page is decoded at full preview resolution; a cache holds at most three full images with a 32 MiB cost limit. Rapid selection is generation-guarded; stale results cannot replace the current selection. No PDF conversion or final-page scan occurs. Fixed 900×750 preferred size and the existing 8-point image inset are deliberately retained for this trial; sidebar width is 124 points. Eligible inner image extensions: JPEG, PNG, GIF (first frame), BMP, TIFF (first image), HEIC/HEIF, WebP and AVIF, subject to host ImageIO support.

Limits:

- No total archive-file size cap. At most 10,000 archive entries; metadata enumeration can still cost time for large archives.
- 32 MiB decompressed bytes per image; image dimensions at most 20,000 per side and 40 million pixels.
- Thumbnail output at most 4096 pixels per side; full preview images at most 1600. Sidebar images at most 160. First-readable fallback is limited to eight candidates / five seconds between attempts.
- Encrypted archives and archives identified as solid by XADMaster, links, hidden/metadata paths and unsupported images are skipped or rejected. Unknown-size streams are read with the same strict 32 MiB streaming limit. No password UI or extraction to disk. A compression stream around TAR/CPIO may be unwrapped once in memory, limited to 32 MiB expanded container bytes and a cooperative three-second read deadline. General nested archives are not recursively opened.
- Reads check a three-second deadline between stream reads; initial cover search also checks five seconds between candidates. These are cooperative limits, **not a hard timeout inside XADMaster parsing/decompression, ImageIO, image rendering**. The Quick Look host also controls extension lifetime. Adversarial-parser isolation/fuzzing is outside this initial validation.
- Read operations release the archive/file handle after decoding and reject a changed file size/modification date.

## OS, identifiers, signing and packaging

The containing app remains macOS **10.14+**. Both extensions are **10.15+** again. Operation on 10.14 and 10.15 has not been tested; validation below ran on macOS 15.8.1 / arm64. Intel slices are built and inspected, not executed on Intel hardware.

The extensions additionally register the precise UTTypes already declared by the main app for these archive formats; they do not register the generic `public.archive` type. The app imports established CBZ/CBR and RAR UTTypes; ZIP uses the system type. Both extension lists include these base types plus compatible comic UTTypes used by other viewers:

| Extension | Base UTType |
| --- | --- |
| CBZ | `cx.c3.cbz-archive` |
| CBR | `cx.c3.cbr-archive` |
| ZIP | `public.zip-archive` |
| RAR | `com.rarlab.rar-archive` |

ZIP/RAR document declarations now also specify `LSItemContentTypes`. Existing document icon references, extension aliases and `LSHandlerRank=Alternate` remain unchanged. RAR is imported, not claimed as an exported proprietary type. Host UTType lookup confirmed all four identifiers above. Imported declarations do not give these extensions exclusive handling priority.

Registering the ZIP/RAR base types broadens competition to ordinary archives and conforming types, in addition to comic files. Another archive extension or an OS provider can win selection. If cooViewer is selected for an archive with no supported images, it returns an error; the OS is not guaranteed to try another provider afterwards. No default application or competing extension preference is changed by this implementation.

App, extensions and embedded project frameworks use **ad hoc signing**, without Developer ID, new credentials, or notarization. Extension entitlements are App Sandbox and user-selected read-only file access. The release checker accepts sealed ad hoc resources, verifies nested signatures, and continues rejecting personal signing/provisioning material.

Build products now default to `/tmp/cooViewer-release-products`, outside iCloud, because Finder metadata on iCloud build products caused code signing to fail. `COOVIEWER_BUILD_ROOT` overrides this root in both build scripts. Do not override `MACOSX_DEPLOYMENT_TARGET` globally: doing so would also override the extension targets.

```sh
./script/build_and_run.sh
./script/test_quicklook.sh
```

For packaging, `COOVIEWER_DIST_ROOT` can select an isolated output directory. To avoid changing the sibling Homebrew tap, pass `--cask-out` explicitly during local packaging checks. Packaging does not imply permission to upload; no upload was performed.

## Validation and timing

The final 1.7.1 synthetic suite covers four-format provider callbacks, expanded archive families, a valid ZIP above 256 MiB, safety limits, first-only full decode, on-demand page loading and cached page reuse. It also covers 25 selectable pages, initially absent offscreen thumbnails, thumbnail creation after scrolling, page-25 selection and first-image-only compact panes. Release Universal builds and strict ad hoc bundle verification passed. Earlier installed five-page UI was verified in Finder; the final 25-page/compact rules are validated by controller regression tests, not a completed post-install UI inspection.

One sample of the final twenty-five-page controller on a synthetic seventy-image archive measured **44.691 ms** to the first-image callback and **67.457 ms** from the same start until the first visible sidebar thumbnail was ready. These are direct controller timings, excluding Finder startup/final compositor paint; filesystem caches may be warm. Low-resolution thumbnails still require archive entry decompression. No PDF conversion is performed. Intel/older-OS execution and all legacy compression variants remain unverified. No public release has been updated for 1.7.1.

The sidebar is transparent, with no individual button bezels or selection fills, visible page numbers or leading-page annotation. Page numbers remain only as accessibility labels for assistive technology; unreadable pages use a disabled thumbnail and an error tooltip.

## Compact pane and 25-page trial

Wide previews expose up to 25 image candidates. Thumbnail rows are generated only when visible and loaded as the sidebar scrolls; full-resolution page images remain on-demand. A compact layout (width under 600 points or height under 480 points) hides the sidebar and does not schedule sidebar thumbnail generation. The content image then occupies the available width. A one-image archive also hides the sidebar. These are responsive layout rules, not reliable identification of Finder versus Spacebar: the public preview callback does not supply a presentation-source flag. A wide Finder pane may therefore show the sidebar and a small Spacebar window may hide it.

Regression checks cover 25 selectable pages, no offscreen page-25 thumbnail at startup, generating that thumbnail after scrolling, full decoding only on page selection, and compact-pane first-image-only behavior. NSButton may supply a 1×1 placeholder image, so completed thumbnail indexes are tracked explicitly rather than inferred from a non-nil button image.

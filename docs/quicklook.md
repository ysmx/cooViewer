# Quick Look extensions (development)

cooViewer embeds two independent macOS app extensions:

- `jp.coo.cooViewer.thumbnail`: Finder thumbnail, using `QLThumbnailProvider`.
- `jp.coo.cooViewer.preview`: view-based Quick Look preview, using `QLPreviewingController` and one large aspect-fit image. No PDF, page list or page-navigation UI is generated.

Both support **CBZ, CBR, ZIP and RAR** containing readable images. Archives without images return an error rather than a fabricated thumbnail. Ordinary images, PDF, CB7/7z, CBT/tar and folders are not registered by these extensions. Multipart archives are outside the supported scope. The main viewer's existing format support remains unchanged. In the corrected 1.7.0, Preview displays only the first readable image. The Finder thumbnail provider remains independent.

## Reader and limits

Both targets compile the same UI-independent `Sources/QuickLook/Shared/COComicArchive` reader and link the project's existing XADMaster and UniversalDetector frameworks. No Simple Comic implementation or binaries are included. Each extension embeds its own framework copies because this project's framework install names use `@executable_path/../Frameworks`.

Archive metadata is enumerated and naturally sorted without decoding the image entries. Both providers stop immediately after the first readable image, with the existing fallback limit of eight candidates / five seconds checked between attempts. Preview never reads or decodes later candidates after success. It displays the decoded image directly at a longest-edge limit of 3072, preserving aspect ratio and filling the window height. Eligible inner image extensions: JPEG, PNG, GIF (first frame), BMP, TIFF (first image), HEIC/HEIF, WebP and AVIF, subject to host ImageIO support.

Limits:

- 256 MiB archive file; at most 10,000 archive entries.
- 32 MiB decompressed bytes per image; image dimensions at most 20,000 per side and 40 million pixels.
- Thumbnail output at most 4096 pixels per side. Preview decodes only one successful image, with a longest-edge limit of 3072. There is no PDF/JPEG conversion, aggregate book raster budget or 64-page scan.
- Encrypted archives and archives identified as solid by XADMaster, links, unknown-size entries, hidden/metadata paths and unsupported images are skipped or rejected. No password UI, recursion into nested archives, or extraction to disk.
- Reads check a three-second deadline between stream reads; initial cover search also checks five seconds between candidates. These are cooperative limits, **not a hard timeout inside XADMaster parsing/decompression, ImageIO, image rendering**. The Quick Look host also controls extension lifetime. Adversarial-parser isolation/fuzzing is outside this initial validation.
- Read operations release the archive/file handle after decoding and reject a changed file size/modification date.

## OS, identifiers, signing and packaging

The containing app remains macOS **10.14+**. Both extensions have a **10.15** deployment target. Operation on 10.14 and 10.15 has not been tested; validation below ran on macOS 15.8.1 / arm64. Intel slices are built and inspected, not executed on Intel hardware.

The app imports established CBZ/CBR and RAR UTTypes; ZIP uses the system type. Both extension lists include these base types plus compatible comic UTTypes used by other viewers:

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

## Validation and performance

The final app and both extensions use marketing and build version **1.7.0**. Release Universal builds and strict nested ad hoc signature verification passed on macOS 15.8.1 / arm64. The synthetic test suite exercises all four formats, natural ordering, fallback after a corrupt first image, no-image/empty/broken/encrypted archives, links and unsafe paths, size limits, image dimensions, provider callbacks, single-success decode counts and image-fit geometry. Run `script/test_quicklook.sh`; use `python3 script/quicklook-tests/CheckBundle.py /path/to/cooViewer.app` to verify bundle integration. Intel and older-macOS execution remain untested.

A 900×750-point preview has an 884×734 viewport; the 1600×2400 test image displays at approximately 489×734 points. Finder was inspected with synthetic ZIP, CBZ, CBR and RAR files after installation. The large ZIP grid was visually checked, with no page list or navigation buttons. The executing provider path was the installed app's `Contents/PlugIns/cooViewerPreview.appex/Contents/MacOS/cooViewerPreview`; logs identified the single-image implementation with one read, one decode attempt and one successful decode. Provider preparation for these fixtures took about 20–35 ms, excluding Finder startup and final display. Updating an already-running extension can temporarily retain the old code until its preview session exits.

Three independent process samples per fixture compared the superseded multipage implementation with the single-image implementation. Median provider-call-to-callback times (including controller setup, excluding Finder startup and final paint):

| Synthetic fixture | Previous ms | Current ms | Successful decodes |
| --- | ---: | ---: | --- |
| Two 1600×2400 images | 230.022 | 164.079 | 2 → 1 |
| Seventy 1600×2400 images | 3598.906 | 138.626 | 64 → 1 |
| Large 4000×6000 first image | 358.141 | 308.265 | 2 → 1 |
| Broken first image then two valid images | 212.412 | 135.717 | 2 → 1 |

For seventy pages, metadata enumeration/sorting took 2.849 ms in the corrected implementation while decoding fell from 2281.205 to 24.055 ms. The broken-first case makes two attempts, then stops at one successful decode. Large-image decode cost remains. These were direct provider measurements, not Quick Look cache timings; filesystem caches may be warm. No superseded implementation or trial binary is shipped.

Public Gatekeeper/notarization acceptance, all RAR compression variants, parser fuzzing and Intel/older-OS runtime verification remain outside this local validation. No default application, competing extension or system security preference is changed.

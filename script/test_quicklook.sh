#!/usr/bin/env bash
# Exercises real shared reader and preview controller with synthetic ZIP/RAR data.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d /tmp/cooViewer-quicklook-tests.XXXXXX)"
if [[ "${COOVIEWER_KEEP_TEST_OUTPUT:-0}" == 1 ]]; then
  echo "Test output: $TEST_DIR"
else
  trap 'rm -rf "$TEST_DIR"' EXIT
fi
mkdir -p "$TEST_DIR/bin"
ln -s "$ROOT_DIR/Frameworks" "$TEST_DIR/Frameworks"
python3 "$ROOT_DIR/script/quicklook-tests/make_fixtures.py" "$TEST_DIR/fixtures"
xcrun clang -g -fobjc-arc -fmodules -fmodules-cache-path="$TEST_DIR/modules" -mmacosx-version-min=10.15 \
  -I "$ROOT_DIR/Sources/QuickLook/Shared" -F "$ROOT_DIR/Frameworks" \
  -framework XADMaster -framework AppKit -framework ImageIO -framework Quartz -framework QuickLookThumbnailing \
  -Wl,-rpath,"$ROOT_DIR/Frameworks" \
  "$ROOT_DIR/Sources/QuickLook/Shared/COComicArchive.m" \
  "$ROOT_DIR/Sources/QuickLook/Preview/PreviewViewController.m" \
  "$ROOT_DIR/Sources/QuickLook/Thumbnail/ThumbnailProvider.m" \
  "$ROOT_DIR/script/quicklook-tests/SmokeTests.m" -o "$TEST_DIR/bin/smoke-tests"
"$TEST_DIR/bin/smoke-tests" "$TEST_DIR/fixtures"

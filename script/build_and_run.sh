#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="cooViewer"
BUNDLE_ID="jp.coo.cooViewer"
PROJECT="cooViewer.xcodeproj"
SCHEME="cooViewer"
CONFIGURATION="Deployment"
DEPLOYMENT_TARGET="10.14"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="/tmp/cooViewer-release-derived"
APP_BUNDLE="$ROOT_DIR/build/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
APP_BUNDLE_REL="build/$CONFIGURATION/$APP_NAME.app"

build_app() {
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    build
}

open_app() {
  sleep 1
  if /usr/bin/open -n "$APP_BUNDLE"; then
    return 0
  fi
  sleep 1
  /usr/bin/open -n "$APP_BUNDLE"
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
build_app

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    /bin/ps -o comm= -ax | /usr/bin/grep -F "/$APP_NAME.app/Contents/MacOS/$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac

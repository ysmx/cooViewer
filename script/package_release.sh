#!/usr/bin/env bash
set -euo pipefail

# Release packaging only.
#
# Do not use this for normal development builds, even when checking the
# Release configuration. Development build/run checks should use:
#
#   ./script/build_and_run.sh
#
# This script creates dist artifacts, generates a Homebrew cask file, and can
# upload a zip to GitHub Releases when --upload is passed.

APP_NAME="cooViewer"
PROJECT="cooViewer.xcodeproj"
SCHEME="cooViewer"
CONFIGURATION="Release"
DEPLOYMENT_TARGET="10.14"
GITHUB_REPO="ysmx/cooViewer"
CASK_TOKEN="cooviewer"
CASK_FILE_NAME="cooviewer.rb"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="/tmp/cooViewer-release-derived"
BUILD_APP="$ROOT_DIR/build/$CONFIGURATION/$APP_NAME.app"
INFO_PLIST="$ROOT_DIR/Info.plist"

FORCE=0
SKIP_BUILD=0
UPLOAD=0
CASK_OUT=""
VERSION=""

usage() {
  cat <<EOF
usage: $0 [--force] [--skip-build] [--upload] [--cask-out PATH] [VERSION]

Builds a Release app bundle, verifies it does not contain personal signing
or local-user traces, creates dist/vVERSION/$APP_NAME.zip, generates a
Homebrew cask file, and verifies the cask sha256 matches the zip.

With --upload, the zip is uploaded to the matching GitHub Release tag.
If the GitHub Release does not exist yet, it is created from the existing
remote tag and the latest release body is reused.

If VERSION is omitted, CFBundleShortVersionString is read from Info.plist.
EOF
}

while (($#)); do
  case "$1" in
    --force)
      FORCE=1
      ;;
    --skip-build)
      SKIP_BUILD=1
      ;;
    --upload)
      UPLOAD=1
      ;;
    --cask-out)
      if [[ $# -lt 2 ]]; then
        echo "--cask-out requires a path" >&2
        exit 2
      fi
      CASK_OUT="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$VERSION" ]]; then
        echo "version specified more than once" >&2
        usage >&2
        exit 2
      fi
      VERSION="${1#v}"
      ;;
  esac
  shift
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
fi

DIST_DIR_REL="dist/v$VERSION"
STAGING_APP_REL="$DIST_DIR_REL/$APP_NAME.app"
ZIP_PATH_REL="$DIST_DIR_REL/$APP_NAME.zip"
CASK_PATH_REL="$DIST_DIR_REL/$CASK_FILE_NAME"
DEFAULT_CASK_OUT="$ROOT_DIR/../homebrew-cooviewer/Casks/$CASK_FILE_NAME"
if [[ -z "$CASK_OUT" ]]; then
  # Prefer the sibling Homebrew tap checkout when it exists. This keeps the
  # normal release flow ready for committing the cask update, while still
  # falling back to dist/ on machines that only have this repository.
  if [[ -d "$(dirname "$DEFAULT_CASK_OUT")" ]]; then
    CASK_OUT="$DEFAULT_CASK_OUT"
  else
    CASK_OUT="$CASK_PATH_REL"
  fi
fi

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

fail_if_found_fixed() {
  local needle="$1"
  local target="$2"
  if [[ -z "$needle" ]]; then
    return
  fi
  if command -v rg >/dev/null 2>&1; then
    if rg -a -n -F "$needle" "$target"; then
      echo "found forbidden fixed string: $needle" >&2
      exit 1
    fi
  elif grep -R -a -n -F "$needle" "$target"; then
    echo "found forbidden fixed string: $needle" >&2
    exit 1
  fi
}

fail_if_found_regex() {
  local pattern="$1"
  local target="$2"
  if command -v rg >/dev/null 2>&1; then
    if rg -a -n "$pattern" "$target"; then
      echo "found forbidden pattern: $pattern" >&2
      exit 1
    fi
  elif grep -R -a -n -E "$pattern" "$target"; then
    echo "found forbidden pattern: $pattern" >&2
    exit 1
  fi
}

check_codesign_output() {
  local path="$1"
  local output
  local display_output
  output="$(codesign -dvvv "$path" 2>&1)"
  display_output="${output//$ROOT_DIR/.}"
  printf '%s\n' "$display_output"

  if printf '%s\n' "$output" | grep -E 'Developer ID|Apple Development' >/dev/null; then
    echo "personal or certificate-based code signature found in: $path" >&2
    exit 1
  fi

  # Swift's bundled runtime dylibs (e.g. libswiftObjectiveC.dylib) carry
  # Apple's own "Software Signing" certificate, chained to Apple Root CA -
  # that's Apple's identity, not the developer's, so it's fine to ship as-is.
  # Anything NOT chained to Apple Root CA still has to clear the
  # TeamIdentifier check below.
  if printf '%s\n' "$output" | grep -F 'Authority=Apple Root CA' >/dev/null; then
    return
  fi

  if printf '%s\n' "$output" | grep -F 'TeamIdentifier=' | grep -vF 'TeamIdentifier=not set' >/dev/null; then
    echo "team identifier found in: $path" >&2
    exit 1
  fi
}

verify_artifact() {
  local bundle_version
  bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$STAGING_APP_REL/Contents/Info.plist")"
  if [[ "$bundle_version" != "$VERSION" ]]; then
    echo "bundle version mismatch: expected $VERSION, got $bundle_version" >&2
    exit 1
  fi

  check_codesign_output "$STAGING_APP_REL"

  local framework_binary
  while IFS= read -r framework_binary; do
    check_codesign_output "$framework_binary"
  done < <(find "$STAGING_APP_REL/Contents/Frameworks" -type f -perm +111 -maxdepth 4 -print)

  if find "$STAGING_APP_REL" -name _CodeSignature -print -quit | grep . >/dev/null; then
    echo "CodeSignature resources found in app bundle" >&2
    exit 1
  fi

  if find "$STAGING_APP_REL" -name embedded.provisionprofile -print -quit | grep . >/dev/null; then
    echo "embedded provisioning profile found in app bundle" >&2
    exit 1
  fi

  fail_if_found_fixed "$(id -un)" "$STAGING_APP_REL"
  fail_if_found_fixed "$HOME" "$STAGING_APP_REL"
  fail_if_found_fixed "/Users/" "$STAGING_APP_REL"
  fail_if_found_regex 'Developer ID|Apple Development|TeamIdentifier|CODE_SIGN|PROVISIONING|\.cer|\.p12' "$STAGING_APP_REL"
}

zip_sha256() {
  shasum -a 256 "$ZIP_PATH_REL" | awk '{print $1}'
}

write_cask() {
  local sha="$1"
  local cask_dir
  cask_dir="$(dirname "$CASK_OUT")"
  mkdir -p "$cask_dir"
  cat > "$CASK_OUT" <<EOF
cask "$CASK_TOKEN" do
  version "$VERSION"
  sha256 "$sha"

  url "https://github.com/$GITHUB_REPO/releases/download/v#{version}/$APP_NAME.zip"
  name "$APP_NAME"
  desc "macOS image viewer for comics/manga. macOS 10.14+ Universal binary. Supports ZIP, RAR, CBZ, CBR, 7Z, PDF, etc."
  homepage "https://github.com/$GITHUB_REPO"

  app "$APP_NAME.app"

  postflight do
    system_command "/usr/bin/xattr",
      args: ["-dr", "com.apple.quarantine", "#{appdir}/$APP_NAME.app"]
  end
end
EOF
}

verify_cask_sha256() {
  local expected_sha="$1"
  local cask_sha
  cask_sha="$(awk '/^[[:space:]]*sha256 / { gsub(/"/, "", $2); print $2; exit }' "$CASK_OUT")"
  if [[ -z "$cask_sha" ]]; then
    echo "sha256 entry not found in cask: $CASK_OUT" >&2
    exit 1
  fi
  if [[ "$cask_sha" != "$expected_sha" ]]; then
    echo "cask sha256 mismatch: cask=$cask_sha zip=$expected_sha" >&2
    exit 1
  fi
}

github_credentials() {
  local creds
  creds="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill)"
  GITHUB_USER="$(printf '%s\n' "$creds" | awk -F= '/^username=/{print $2; exit}')"
  GITHUB_PASSWORD="$(printf '%s\n' "$creds" | awk -F= '/^password=/{print $2; exit}')"
  if [[ -z "${GITHUB_USER:-}" || -z "${GITHUB_PASSWORD:-}" ]]; then
    echo "GitHub credentials not found in git credential helper" >&2
    exit 1
  fi
}

ensure_release_json() {
	local release_json="$1"
	local status
	github_credentials
	status="$(curl -sS \
		-u "$GITHUB_USER:$GITHUB_PASSWORD" \
		-H "Accept: application/vnd.github+json" \
		-w "%{http_code}" \
		-o "$release_json" \
		"https://api.github.com/repos/$GITHUB_REPO/releases/tags/v$VERSION")"
	case "$status" in
		200)
			return
			;;
		404)
			create_release_json "$release_json"
			;;
		*)
			echo "failed to fetch GitHub Release for v$VERSION (HTTP $status)" >&2
			cat "$release_json" >&2
			exit 1
			;;
	esac
}

ensure_remote_tag_exists() {
	local tag_json
	local status
	tag_json="$(mktemp)"
	status="$(curl -sS \
		-u "$GITHUB_USER:$GITHUB_PASSWORD" \
		-H "Accept: application/vnd.github+json" \
		-w "%{http_code}" \
		-o "$tag_json" \
		"https://api.github.com/repos/$GITHUB_REPO/git/ref/tags/v$VERSION")"
	if [[ "$status" != "200" ]]; then
		echo "remote tag v$VERSION was not found on GitHub; push the tag before creating the release" >&2
		cat "$tag_json" >&2
		exit 1
	fi
}

latest_release_body() {
	local latest_json
	local status
	latest_json="$(mktemp)"
	status="$(curl -sS \
		-u "$GITHUB_USER:$GITHUB_PASSWORD" \
		-H "Accept: application/vnd.github+json" \
		-w "%{http_code}" \
		-o "$latest_json" \
		"https://api.github.com/repos/$GITHUB_REPO/releases/latest")"
	if [[ "$status" == "200" ]]; then
		jq -r '.body // ""' "$latest_json"
	else
		printf ''
	fi
}

create_release_json() {
	local release_json="$1"
	local body
	local payload
	body="$(latest_release_body)"
	payload="$(mktemp)"
	ensure_remote_tag_exists
	jq -n \
		--arg tag_name "v$VERSION" \
		--arg name "v$VERSION" \
		--arg body "$body" \
		'{tag_name:$tag_name,name:$name,body:$body,draft:false,prerelease:false}' \
		> "$payload"
	curl -fsSL \
		-u "$GITHUB_USER:$GITHUB_PASSWORD" \
		-H "Accept: application/vnd.github+json" \
		-H "Content-Type: application/json" \
		-d @"$payload" \
		"https://api.github.com/repos/$GITHUB_REPO/releases" \
		-o "$release_json"
	echo "created GitHub Release: v$VERSION"
}

delete_existing_asset() {
  local release_json="$1"
  local asset_id
  asset_id="$(jq -r --arg name "$APP_NAME.zip" '.assets[]? | select(.name == $name) | .id' "$release_json" | head -n 1)"
  if [[ -z "$asset_id" || "$asset_id" == "null" ]]; then
    return
  fi
  curl -fsSL \
    -u "$GITHUB_USER:$GITHUB_PASSWORD" \
    -H "Accept: application/vnd.github+json" \
    -X DELETE \
    "https://api.github.com/repos/$GITHUB_REPO/releases/assets/$asset_id" \
    -o /dev/null
}

upload_zip() {
  local release_json
  local release_id
  local asset_json
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for --upload" >&2
    exit 1
  fi
  release_json="$(mktemp)"
  asset_json="$(mktemp)"

  ensure_release_json "$release_json"
  delete_existing_asset "$release_json"
  release_id="$(jq -r '.id' "$release_json")"
  if [[ -z "$release_id" || "$release_id" == "null" ]]; then
    echo "release id not found for v$VERSION" >&2
    exit 1
  fi

  curl -fsSL \
    -u "$GITHUB_USER:$GITHUB_PASSWORD" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/zip" \
    --data-binary @"$ZIP_PATH_REL" \
    "https://uploads.github.com/repos/$GITHUB_REPO/releases/$release_id/assets?name=$APP_NAME.zip" \
    -o "$asset_json"

  jq -r '.browser_download_url' "$asset_json"
}

if [[ "$FORCE" -eq 0 && ( -e "$ROOT_DIR/$STAGING_APP_REL" || -e "$ROOT_DIR/$ZIP_PATH_REL" ) ]]; then
  echo "output already exists: $DIST_DIR_REL" >&2
  echo "use --force to overwrite" >&2
  exit 1
fi

cd "$ROOT_DIR"

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  build_app
fi

if [[ ! -d "$BUILD_APP" ]]; then
  echo "build product not found: $BUILD_APP" >&2
  exit 1
fi

mkdir -p "$DIST_DIR_REL"
if [[ "$FORCE" -eq 1 ]]; then
  rm -rf "$STAGING_APP_REL"
  rm -f "$ZIP_PATH_REL"
fi

ditto --norsrc "$BUILD_APP" "$STAGING_APP_REL"
verify_artifact

(
  cd "$DIST_DIR_REL"
  ditto -c -k --norsrc --keepParent "$APP_NAME.app" "$APP_NAME.zip"
)

ZIP_SHA="$(zip_sha256)"
printf '%s  %s\n' "$ZIP_SHA" "$ZIP_PATH_REL"
write_cask "$ZIP_SHA"
verify_cask_sha256 "$ZIP_SHA"
echo "created: $CASK_OUT"

if [[ "$UPLOAD" -eq 1 ]]; then
  echo "uploaded: $(upload_zip)"
fi

echo "created: $ZIP_PATH_REL"

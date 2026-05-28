#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This warning-expected DMG preview script must be run on macOS." >&2
  exit 1
fi

require_command awk
require_command codesign
require_command hdiutil
require_command shasum

checkpoint="$(grep -Eo 'v[0-9]+[.][0-9]+[.][0-9]+' Sources/HazakuraLLMManagerCore/Models/SourceCheckpointInfo.swift | head -n 1)"
if [[ -z "$checkpoint" ]]; then
  echo "Could not read SourceCheckpointInfo.current.identifier." >&2
  exit 1
fi

version="${checkpoint#v}"
machine_arch="$(uname -m)"
case "$machine_arch" in
  arm64)
    arch="aarch64"
    ;;
  x86_64)
    arch="x64"
    ;;
  *)
    arch="$machine_arch"
    ;;
esac

product_name="hazakura-lantern"
app_name="Hazakura Lantern.app"
app_path="dist/$app_name"
dmg_dir="dist/dmg"
evidence_dir="dist/release-evidence"
dmg_info="$evidence_dir/dmg-info.txt"
dmg_path="$dmg_dir/${product_name}_${version}_${arch}-warning-expected.dmg"
checksum_path="${dmg_path}.sha256"
mount_dir=""
temp_report=""
dmg_verified=0

cleanup() {
  if [[ -n "$mount_dir" && -d "$mount_dir" ]]; then
    hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
    rm -rf "$mount_dir"
  fi
  if [[ "$dmg_verified" != "1" ]]; then
    rm -f "$dmg_path" "$checksum_path" "$dmg_info"
  fi
  if [[ -n "$temp_report" ]]; then
    rm -f "$temp_report"
  fi
}
trap cleanup EXIT

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  script/build_and_run.sh --bundle-only
fi

if [[ ! -d "$app_path" ]]; then
  echo "Missing built app: $app_path" >&2
  echo "Run script/build_and_run.sh --bundle-only before setting SKIP_BUILD=1." >&2
  exit 1
fi

codesign --force --deep --sign - --options runtime "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")"
bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
bundle_build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_path/Contents/Info.plist")"
app_cdhash="$(codesign -dvvv "$app_path" 2>&1 | awk -F= '/^CDHash=/{ print $2; exit }')"

if [[ -z "$app_cdhash" ]]; then
  echo "Could not read app CDHash: $app_path" >&2
  exit 1
fi

mkdir -p "$dmg_dir" "$evidence_dir"
staging_root="$(mktemp -d "$dmg_dir/${product_name}-dmg-root.XXXXXX")"
trap 'rm -rf "$staging_root"; cleanup' EXIT

cp -a "$app_path" "$staging_root/"
ln -s /Applications "$staging_root/Applications"

hdiutil create \
  -volname "Hazakura Lantern $version" \
  -srcfolder "$staging_root" \
  -ov \
  -format UDZO \
  "$dmg_path"

hdiutil verify "$dmg_path"

mount_dir="$(mktemp -d "${TMPDIR:-/tmp}/hazakura-lantern-dmg-mount.XXXXXX")"
hdiutil attach -readonly -nobrowse -mountpoint "$mount_dir" "$dmg_path" >/dev/null

mounted_app_path="$mount_dir/$app_name"
if [[ ! -d "$mounted_app_path" ]]; then
  echo "DMG mount verification failed because the app bundle is missing from the mounted image." >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$mounted_app_path"
mounted_bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$mounted_app_path/Contents/Info.plist")"
mounted_bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$mounted_app_path/Contents/Info.plist")"
mounted_bundle_build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$mounted_app_path/Contents/Info.plist")"
mounted_app_cdhash="$(codesign -dvvv "$mounted_app_path" 2>&1 | awk -F= '/^CDHash=/{ print $2; exit }')"

if [[ "$mounted_bundle_identifier" != "$bundle_identifier" ||
  "$mounted_bundle_version" != "$bundle_version" ||
  "$mounted_bundle_build" != "$bundle_build" ||
  "$mounted_app_cdhash" != "$app_cdhash" ]]; then
  echo "DMG mount verification failed because the mounted app identity does not match the source app." >&2
  exit 1
fi

hdiutil detach "$mount_dir" >/dev/null
rm -rf "$mount_dir"
mount_dir=""

shasum -a 256 "$dmg_path" > "$checksum_path"
shasum -c "$checksum_path"

dmg_sha="$(awk '{print $1}' "$checksum_path")"
temp_report="$(mktemp "$evidence_dir/dmg-info.XXXXXX")"
{
  echo "DMG checks passed."
  echo "DMG: $dmg_path"
  echo "DMG SHA-256: $dmg_sha"
  echo "Volume name: Hazakura Lantern $version"
  echo "Format: UDZO"
  echo "Source app: $app_path"
  echo "Bundle ID: $bundle_identifier"
  echo "Version: $bundle_version"
  echo "Build: $bundle_build"
  echo "CDHash: $app_cdhash"
  echo "hdiutil verify: passed"
  echo "hdiutil attach: passed"
  echo "Mounted app: $app_name"
  echo "Mounted bundle ID: $mounted_bundle_identifier"
  echo "Mounted version: $mounted_bundle_version"
  echo "Mounted build: $mounted_bundle_build"
  echo "Mounted CDHash: $mounted_app_cdhash"
} >"$temp_report"
mv "$temp_report" "$dmg_info"
temp_report=""
dmg_verified=1

echo "DMG: $dmg_path"
echo "SHA256: $dmg_sha"
echo "Checksum file: $checksum_path"
echo "Evidence: $dmg_info"

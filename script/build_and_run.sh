#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_EXECUTABLE="HazakuraLLMManager"
APP_DISPLAY_NAME="Hazakura Lantern"
APP_BUNDLE_NAME="$APP_DISPLAY_NAME.app"
BUNDLE_ID="dev.hazakura.llmmanager"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE_RELATIVE="dist/$APP_BUNDLE_NAME"
APP_BUNDLE="$ROOT_DIR/$APP_BUNDLE_RELATIVE"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_EXECUTABLE"
INFO_PLIST="$APP_CONTENTS/Info.plist"

SWIFT_BUILD_FLAGS=(--disable-sandbox)

stop_app() {
  pkill -x "$APP_EXECUTABLE" >/dev/null 2>&1 || true
}

stop_app

if [[ "$MODE" == "--stop" || "$MODE" == "stop" ]]; then
  echo "$APP_DISPLAY_NAME stop request completed."
  exit 0
fi

swift build "${SWIFT_BUILD_FLAGS[@]}"
BUILD_BINARY="$(swift build "${SWIFT_BUILD_FLAGS[@]}" --show-bin-path)/$APP_EXECUTABLE"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_EXECUTABLE</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/touch "$APP_BUNDLE"
  sleep 0.2
  (
    cd "$ROOT_DIR"
    /usr/bin/open -W -n "$APP_BUNDLE_RELATIVE" &
    OPEN_PID=$!
    sleep 1
    if kill -0 "$OPEN_PID" >/dev/null 2>&1; then
      kill "$OPEN_PID" >/dev/null 2>&1 || true
      return 0
    fi
    wait "$OPEN_PID"
  )
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    trap stop_app EXIT
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_EXECUTABLE\""
    ;;
  --telemetry|telemetry)
    trap stop_app EXIT
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    trap stop_app EXIT
    open_app
    echo "$APP_DISPLAY_NAME launch request completed."
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--stop]" >&2
    exit 2
    ;;
esac

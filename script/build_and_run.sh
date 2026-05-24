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
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_EXECUTABLE"
INFO_PLIST="$APP_CONTENTS/Info.plist"

SWIFT_BUILD_FLAGS=(--disable-sandbox)

wait_for_exit() {
  local pid
  local attempt

  for attempt in {1..30}; do
    local any_running=0

    for pid in "$@"; do
      if kill -0 "$pid" >/dev/null 2>&1; then
        any_running=1
        break
      fi
    done

    if [[ "$any_running" == "0" ]]; then
      return 0
    fi

    sleep 0.1
  done

  return 1
}

terminate_pids() {
  local pid
  local live_pids=()

  for pid in "$@"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      live_pids+=("$pid")
    fi
  done

  if [[ "${#live_pids[@]}" == "0" ]]; then
    return 0
  fi

  kill -TERM "${live_pids[@]}" >/dev/null 2>&1 || true
  if ! wait_for_exit "${live_pids[@]}"; then
    kill -KILL "${live_pids[@]}" >/dev/null 2>&1 || true
    wait_for_exit "${live_pids[@]}" || true
  fi
}

stop_app() {
  local app_pid
  local child_pid
  local app_pids=()
  local child_pids=()

  while IFS= read -r app_pid; do
    [[ -n "$app_pid" ]] || continue
    app_pids+=("$app_pid")

    while IFS= read -r child_pid; do
      [[ -n "$child_pid" ]] || continue
      child_pids+=("$child_pid")
    done < <(pgrep -P "$app_pid" || true)
  done < <(pgrep -x "$APP_EXECUTABLE" || true)

  if [[ "${#app_pids[@]}" == "0" ]]; then
    return 0
  fi

  terminate_pids "${app_pids[@]}"
  if [[ "${#child_pids[@]}" != "0" ]]; then
    terminate_pids "${child_pids[@]}"
  fi
}

stop_app

if [[ "$MODE" == "--stop" || "$MODE" == "stop" ]]; then
  echo "$APP_DISPLAY_NAME stop request completed."
  exit 0
fi

swift build "${SWIFT_BUILD_FLAGS[@]}"
BUILD_BIN_DIR="$(swift build "${SWIFT_BUILD_FLAGS[@]}" --show-bin-path)"
BUILD_BINARY="$BUILD_BIN_DIR/$APP_EXECUTABLE"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

find "$BUILD_BIN_DIR" -maxdepth 1 \
  \( -name "*$APP_EXECUTABLE*.resources" -o -name "*$APP_EXECUTABLE*.bundle" \) \
  -exec cp -R {} "$APP_RESOURCES/" \;

find "$BUILD_BIN_DIR" -maxdepth 2 -type d -name "*.lproj" | while IFS= read -r lproj_dir; do
  cp -R "$lproj_dir" "$APP_RESOURCES/"
done

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
    /usr/bin/open -n "$APP_BUNDLE_RELATIVE"
  )
}

wait_for_app_launch() {
  local attempt
  local app_pid

  for attempt in {1..50}; do
    app_pid="$(pgrep -x "$APP_EXECUTABLE" | head -n 1 || true)"
    if [[ -n "$app_pid" ]]; then
      echo "$app_pid"
      return 0
    fi

    sleep 0.1
  done

  return 1
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
    APP_PID="$(wait_for_app_launch)"
    echo "$APP_DISPLAY_NAME launch verified with pid $APP_PID."
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--stop]" >&2
    exit 2
    ;;
esac

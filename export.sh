#!/usr/bin/env bash
# One-click Godot export for macOS & Android. Run ./export.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1 && [[ ! -x "$GODOT_BIN" ]]; then
  echo "❌ Godot executable not found. Install Godot 4 or set GODOT_BIN." >&2
  exit 1
fi

mkdir -p build

echo "▶️ Exporting release build for macOS (Apple Silicon)…"
EXPORT_NAME="3d-snakes-ladders-macos"
EXPORT_PATH="build/${EXPORT_NAME}.app"
"$GODOT_BIN" --headless --path "$SCRIPT_DIR" --export-release "macOS" "$EXPORT_PATH"

echo "▶️ Zipping macOS app for distribution…"
ditto -c -k "$EXPORT_PATH" "${EXPORT_NAME}.zip"
echo "✅ macOS Build complete: ${EXPORT_NAME}.zip"

echo "▶️ Exporting release build for Android APK…"
APK_NAME="3d-snakes-ladders.apk"
"$GODOT_BIN" --headless --path "$SCRIPT_DIR" --export-debug "Android" "build/${APK_NAME}"
cp "build/${APK_NAME}" "${APK_NAME}"
echo "✅ Android APK Build complete: ${APK_NAME}"

ls -lh "${EXPORT_NAME}.zip" "${APK_NAME}"

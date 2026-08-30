#!/usr/bin/env bash
# One-click Godot export for macOS (Apple Silicon). Run ./export.sh
# Requires: Godot 4 on PATH (or set GODOT_BIN) + macOS export templates installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

EXPORT_NAME="3d-snakes-ladders-macos"
EXPORT_PATH="build/${EXPORT_NAME}.app"
GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1 && [[ ! -x "$GODOT_BIN" ]]; then
  echo "❌ Godot executable not found. Install Godot 4 or set GODOT_BIN." >&2
  exit 1
fi

echo "▶️ Exporting release build for macOS (Apple Silicon)…"
"$GODOT_BIN" --headless --path "$SCRIPT_DIR" --export-release "macOS" "$EXPORT_PATH"

echo "▶️ Zipping app for distribution…"
ditto -c -k "$EXPORT_PATH" "${EXPORT_NAME}.zip"

echo "✅ Build complete: ${EXPORT_NAME}.zip"
ls -lh "${EXPORT_NAME}.zip"

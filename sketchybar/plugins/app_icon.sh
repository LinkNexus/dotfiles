#!/bin/bash
# ~/.config/sketchybar/plugins/app_icon.sh
#
# Usage: app_icon.sh "AppName"
# Prints the path to a cached PNG of that app's REAL icon, extracted
# straight from its .app bundle. Empty output means extraction failed
# (caller should fall back to something else, e.g. a letter).

APP_NAME="$1"
CACHE_DIR="$HOME/.config/sketchybar/icon_cache"
mkdir -p "$CACHE_DIR"

SAFE_NAME=$(echo "$APP_NAME" | tr -c 'A-Za-z0-9' '_')
OUT="$CACHE_DIR/${SAFE_NAME}.png"

# Already cached from a previous run -- nothing to do
if [[ -f "$OUT" ]]; then
  echo "$OUT"
  exit 0
fi

# Resolve the .app bundle path via NSWorkspace (in-process Launch
# Services lookup). The old AppleScript "path to application" sent an
# Apple Event, which made macOS pop a permission prompt for every new
# app; this sends none, so it never prompts.
APP_PATH=$(osascript -l JavaScript -e '
  ObjC.import("AppKit");
  const p = $.NSWorkspace.sharedWorkspace.fullPathForApplication("'"$APP_NAME"'");
  p.isNil() ? "" : p.js' 2>/dev/null)
if [[ -z "$APP_PATH" ]]; then
  exit 1
fi

ICON_FILE=$(defaults read "${APP_PATH}/Contents/Info" CFBundleIconFile 2>/dev/null)
[[ "$ICON_FILE" != *.icns ]] && ICON_FILE="${ICON_FILE}.icns"
ICNS_PATH="${APP_PATH}/Contents/Resources/${ICON_FILE}"

# Some newer apps bundle their icon inside a compiled Assets.car
# instead of a loose .icns file -- this technique can't extract those
# (would need a heavier asset-catalog unpacking tool). Fails cleanly.
if [[ ! -f "$ICNS_PATH" ]]; then
  exit 1
fi

# Apple icon artwork has ~18% transparent margin baked in (the icon
# grid), which makes app icons look smaller than native menu bar
# glyphs at the same size. Extract at 48px, center-crop to 40px to
# trim most of that margin, then draw at scale 0.5 -> 20pt, retina.
sips -s format png "$ICNS_PATH" --out "$OUT" --resampleHeightWidthMax 48 >/dev/null 2>&1
sips -c 40 40 "$OUT" >/dev/null 2>&1
if [[ -f "$OUT" ]]; then
  echo "$OUT"
else
  exit 1
fi

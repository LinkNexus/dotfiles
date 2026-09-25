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
DIM="$CACHE_DIR/${SAFE_NAME}_dim.png"

# Renders a 35%-opacity copy of $OUT next to it -- used for app icons
# in unfocused workspaces. sips can't touch alpha, so draw it with
# AppKit via JXA (in-process, no permission prompts).
#
# The size arithmetic is the fiddly part. NSImage.size is in POINTS,
# derived from the file's DPI metadata, while lockFocus allocates its
# backing store at the main display's backingScaleFactor. Sizing the
# destination in raw points therefore made the output pixel size depend
# on both -- and PWA .icns files (Chrome/Safari-generated web apps) come
# out of sips at 72 dpi where every normal app's icon is 144, so their
# 40px source became a 20pt image, became an 80px dim on a 2x display:
# double size, spilling outside its pill. Sizing the destination at
# pixels/backingScale instead pins the output to exactly the source's
# pixel dimensions no matter what either value happens to be.
make_dim() {
  osascript -l JavaScript -e '
    ObjC.import("AppKit");
    const src = $.NSImage.alloc.initWithContentsOfFile("'"$OUT"'");

    // largest representation, in pixels -- not src.size, see above
    let w = 0, h = 0;
    const reps = src.representations;
    for (let i = 0; i < reps.count; i++) {
      const r = reps.objectAtIndex(i);
      if (r.pixelsWide > w) { w = r.pixelsWide; h = r.pixelsHigh; }
    }

    const scale = $.NSScreen.mainScreen.backingScaleFactor;
    const out = $.NSImage.alloc.initWithSize($.NSMakeSize(w / scale, h / scale));
    out.lockFocus;
    src.drawInRectFromRectOperationFraction(
      $.NSMakeRect(0, 0, w / scale, h / scale),
      $.NSMakeRect(0, 0, 0, 0),
      $.NSCompositingOperationSourceOver, 0.35);
    out.unlockFocus;

    const rep = $.NSBitmapImageRep.imageRepWithData(out.TIFFRepresentation);
    const png = rep.representationUsingTypeProperties(
      $.NSBitmapImageFileTypePNG, $.NSDictionary.dictionary);
    png.writeToFileAtomically("'"$DIM"'", true);' >/dev/null 2>&1
}

# Already cached from a previous run -- nothing to do
if [[ -f "$OUT" ]]; then
  [[ -f "$DIM" ]] || make_dim
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
  make_dim
  echo "$OUT"
else
  exit 1
fi

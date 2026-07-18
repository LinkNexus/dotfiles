#!/bin/bash
# ~/.config/sketchybar/plugins/aerospace.sh
#
# Rebuilds one rounded "pill" (SketchyBar bracket) per AeroSpace
# workspace that has at least one open window: a workspace number
# plus the REAL icon of every app running in it, extracted straight
# from each app's .app bundle (see app_icon.sh). Empty workspaces get
# no pill at all.
#
# The rebuild is incremental: existing items are updated in place and
# only stale ones removed, with every change batched into a SINGLE
# sketchybar invocation -- so switching workspaces never shows an
# empty or half-built bar.

CONFIG_DIR="$HOME/.config/sketchybar"
ICON_SCRIPT="$CONFIG_DIR/plugins/app_icon.sh"

FOCUSED=$(aerospace list-workspaces --focused)
NONEMPTY=$(aerospace list-workspaces --monitor focused --empty no)

# Space items/brackets currently in the bar, one per line
EXISTING=$(sketchybar --query bar | python3 -c '
import json, sys
for i in json.load(sys.stdin)["items"]:
    if i.startswith("space"):
        print(i)')

exists() { grep -qxF "$1" <<< "$EXISTING"; }

ARGS=()          # batched item adds/sets/moves/removes
BRACKET_ARGS=()  # batched bracket re-adds (must come after removes)
WANTED=()        # every item we want, in display order

FIRST_PILL=1
for ws in $NONEMPTY; do
  # Invisible spacer between consecutive pills (not part of any bracket)
  if [ "$FIRST_PILL" = "1" ]; then
    FIRST_PILL=0
  else
    GAP="space.$ws.gap"
    exists "$GAP" || ARGS+=(--add item "$GAP" center)
    ARGS+=(--set "$GAP" width=8 icon.drawing=off label.drawing=off background.drawing=off)
    WANTED+=("$GAP")
  fi

  if [ "$ws" = "$FOCUSED" ]; then
    NUM_COLOR="0xffffffff"
    PILL_COLOR="0xd91c1c26"
    PILL_BORDER="0x59ffffff"
  else
    NUM_COLOR="0xff9a9aa5"
    PILL_COLOR="0xb314141c"
    PILL_BORDER="0x33ffffff"
  fi

  # The workspace-number item itself
  exists "space.$ws" || ARGS+=(--add item "space.$ws" center)
  ARGS+=(--set "space.$ws"
         icon="$ws"
         icon.drawing=on
         icon.font="Helvetica Neue:Bold:11.0"
         icon.color="$NUM_COLOR"
         icon.padding_left=9
         icon.padding_right=5
         label.drawing=off
         background.drawing=off)
  WANTED+=("space.$ws")

  MEMBERS=("space.$ws")

  APPS=$(aerospace list-windows --workspace "$ws" --format '%{app-name}' | sort -u)
  i=0
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    i=$((i + 1))
    ITEM="space.$ws.app$i"
    ICON_PNG=$("$ICON_SCRIPT" "$app")

    exists "$ITEM" || ARGS+=(--add item "$ITEM" center)
    if [ -n "$ICON_PNG" ]; then
      ARGS+=(--set "$ITEM"
             icon.drawing=off
             label.drawing=off
             background.image="$ICON_PNG"
             background.image.scale=0.5
             background.drawing=on
             background.color=0x00000000
             padding_left=2
             padding_right=2)
    else
      # Extraction failed (e.g. app stores its icon in a compiled
      # Assets.car instead of a loose .icns) -- fall back to a letter
      ARGS+=(--set "$ITEM"
             icon="${app:0:1}"
             icon.drawing=on
             icon.font="Helvetica Neue:Bold:11.0"
             icon.color="$NUM_COLOR"
             label.drawing=off
             background.drawing=off
             padding_left=2
             padding_right=2)
    fi

    WANTED+=("$ITEM")
    MEMBERS+=("$ITEM")
  done <<< "$APPS"

  # Trailing breathing room inside the pill so the last icon isn't
  # flush against the rounded edge
  [ "$i" -gt 0 ] && ARGS+=(--set "space.$ws.app$i" padding_right=8)

  # Group the number + all its app icons into one rounded pill.
  # Bracket membership changes as apps come and go and can't be
  # edited in place, so brackets are always removed (below) and
  # re-added -- still within the same single sketchybar call.
  BRACKET_ARGS+=(--add bracket "space_bracket.$ws" "${MEMBERS[@]}"
                 --set "space_bracket.$ws"
                       background.drawing=on
                       background.color="$PILL_COLOR"
                       background.border_color="$PILL_BORDER"
                       background.border_width=1
                       background.corner_radius=12
                       background.height=24
                       click_script="aerospace workspace $ws")
done

# Newly added items append at the end of the bar, so enforce display
# order by chaining moves off aerospace_control (always present, first)
PREV="aerospace_control"
for item in "${WANTED[@]}"; do
  ARGS+=(--move "$item" after "$PREV")
  PREV="$item"
done

# Remove stale items (things in the bar we no longer want); all
# brackets are removed here and re-added via BRACKET_ARGS
while IFS= read -r old; do
  [ -z "$old" ] && continue
  case "$old" in
    space_bracket.*) ARGS+=(--remove "$old") ;;
    *)
      case " ${WANTED[*]} " in
        *" $old "*) ;;
        *) ARGS+=(--remove "$old") ;;
      esac ;;
  esac
done <<< "$EXISTING"

sketchybar "${ARGS[@]}" "${BRACKET_ARGS[@]}"

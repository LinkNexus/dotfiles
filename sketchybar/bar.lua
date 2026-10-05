-- ~/.config/sketchybar/bar.lua
--
-- Same non-destructive approach as before: fully transparent bar
-- overlaying the real native menu bar.
--
-- 30 = native menu bar height on this display (NSScreen frame minus
-- visibleFrame) -- must match or items sit higher than menu bar content
--
-- display = 'main' draws the bar on the macOS primary display only,
-- instead of sketchybar's default of every connected display. The
-- built-in copy of this bar is unusable on a dual ultrawide + built-in
-- setup, in two ways a single bar cannot express per-display:
--   - `height` above is one global value, measured at 30pt to match the
--     ultrawide. The notched built-in's menu bar is 33pt (confirmed live
--     via hs.screen: frame().y - fullFrame().y), so the overlay sits too
--     high against its menu bar content.
--   - the workspace pills are `position = 'center'` (see
--     items/scrollspace.lua), and centre on a notched display is exactly
--     where the notch is -- the pills render behind it.
--
-- IMPORTANT: "main" here is the macOS *primary* display -- the one whose
-- fullFrame origin is (0,0), set by dragging the white menu bar in
-- System Settings > Displays > Arrangement. This setting is therefore
-- only correct while the LG ULTRAWIDE is the primary display. It was
-- NOT, originally: the built-in sat at (0,0) with the ultrawide at
-- -2924, so this line pinned the pills to the built-in -- the exact
-- display they're unusable on. Making the ultrawide primary is what
-- makes this right, and it also makes the 30pt height above correct by
-- construction rather than by coincidence.
--
-- Chosen over an explicit `display=<index>` deliberately: indices shift
-- when displays are replugged, and an index pinned to the ultrawide
-- would draw nothing at all when undocked to the built-in alone.
-- Following the menu bar degrades gracefully instead.
sbar.bar({
  height = 30,
  display = 'main',
  color = 0x00000000,
  border_width = 0,
  shadow = false,
  sticky = false,
  topmost = 'window',
  blur_radius = 0,
  y_offset = 0,
})

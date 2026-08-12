-- ~/.config/sketchybar/bar.lua
--
-- Same non-destructive approach as before: fully transparent bar
-- overlaying the real native menu bar.
--
-- 30 = native menu bar height on this display (NSScreen frame minus
-- visibleFrame) -- must match or items sit higher than menu bar content
sbar.bar({
  height = 30,
  color = 0x00000000,
  border_width = 0,
  shadow = false,
  sticky = false,
  topmost = 'window',
  blur_radius = 0,
  y_offset = 0,
})

-- ~/.config/sketchybar/bar.lua
--
-- Same non-destructive approach as before: fully transparent bar
-- overlaying the real native menu bar.
--
-- 30 = native menu bar height on this display (NSScreen frame minus
-- visibleFrame) -- must match or items sit higher than menu bar content
--
-- The bar is drawn only on displays at least MIN_DISPLAY_WIDTH points
-- wide, instead of sketchybar's default of every connected display. The
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
-- Filtering by width replaced `display = 'main'`, which was only right
-- while the ultrawide happened to be the macOS primary display -- and
-- it wasn't always (the built-in at (0,0) pinned the pills to exactly
-- the display they're unusable on). A hardcoded `display=<index>` was
-- no better: arrangement ids shift when displays are replugged. Width
-- is a property of the display itself, so it survives both. It is
-- recomputed on every display_change, and falls back to 'main' when no
-- display qualifies (undocked, built-in only) so the bar never vanishes.
local MIN_DISPLAY_WIDTH = 2000 -- points; built-in is 1470, ultrawide 3008

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

local function updateBarDisplays()
  sbar.exec('sketchybar --query displays', function(displays)
    local ids = {}
    for _, d in ipairs(displays) do
      if d.frame.w >= MIN_DISPLAY_WIDTH then
        table.insert(ids, d['arrangement-id'])
      end
    end
    sbar.bar({ display = #ids > 0 and table.concat(ids, ',') or 'main' })
  end)
end

-- Invisible item: SbarLua subscriptions must hang off an item
local watcher = sbar.add('item', 'bar_display_watcher', { drawing = false })
watcher:subscribe('display_change', updateBarDisplays)
updateBarDisplays()

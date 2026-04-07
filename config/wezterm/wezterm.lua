-- local wezterm = require("wezterm")
-- local config = wezterm.config_builder()
-- local is_darwin = wezterm.target_triple:find("darwin") ~= nil
--
-- -- ── Font ────────────────────────────────────────────────────────────
--
-- config.font = wezterm.font("Cascadia Code NF", {
-- 	weight = "Regular",
-- })
-- config.font_size = 20
--
-- config.font_rules = {
-- 	{
-- 		intensity = "Bold",
-- 		italic = false,
-- 		font = wezterm.font("Cascadia Code NF", { weight = "Bold" }),
-- 	},
-- }
--
-- config.harfbuzz_features = {
-- 	"ss01", -- ligatures set 1
-- 	"ss02",
-- 	"ss03",
-- 	"ss04",
-- 	"ss05",
-- 	"ss06",
-- 	"ss07",
-- 	"ss08",
-- 	"ss19",
-- 	"ss20",
-- 	"liga",
-- 	"calt",
-- }
--
-- -- ── Appearance ──────────────────────────────────────────────────────
-- -- config.color_scheme = "Ayu Dark (Gogh)"
-- -- config.window_background_opacity = 0.65
-- config.macos_window_background_blur = 15
-- config.window_padding = {
-- 	left = 10,
-- 	right = 10,
-- 	top = 0,
-- 	bottom = 10,
-- }
-- config.line_height = 1.1
--
-- -- ── Window decorations ──────────────────────────────────────────────
-- config.window_close_confirmation = "NeverPrompt"
--
-- -- ── Cursor ──────────────────────────────────────────────────────────
-- config.default_cursor_style = "BlinkingBlock"
-- config.cursor_blink_rate = 500
-- config.cursor_blink_ease_in = "Constant"
-- config.cursor_blink_ease_out = "Constant"
--
-- -- ── Tab bar ─────────────────────────────────────────────────────────
-- config.enable_tab_bar = true
-- config.use_fancy_tab_bar = false
-- config.hide_tab_bar_if_only_one_tab = true
-- config.tab_bar_at_bottom = true
-- config.tab_max_width = 32
--
-- -- ── Tab Configuration ──────────────────────────────────────────────
-- -- Customize these settings to control tab display behavior
-- local tab_config = {
-- 	show_time_in_status = true, -- Set to false to hide time in right status
-- }
--
-- -- ── Right Status (Time) ─────────────────────────────────────────────
-- wezterm.on("update-right-status", function(window, pane)
-- 	if not tab_config.show_time_in_status then
-- 		return
-- 	end
--
-- 	local time = wezterm.strftime("%H:%M")
-- 	local date = wezterm.strftime("%a %d")
--
-- 	-- Create time/date display with gruvbox colors
-- 	window:set_right_status(wezterm.format({
-- 		{ Text = " " .. date .. " " },
-- 		{ Text = " " .. time .. " " },
-- 	}))
-- end)
--
-- -- ── Scrollback ──────────────────────────────────────────────────────
-- config.scrollback_lines = 5000
--
-- -- ── Bell ────────────────────────────────────────────────────────────
-- config.audible_bell = "Disabled"
-- config.visual_bell = {
-- 	fade_in_duration_ms = 75,
-- 	fade_out_duration_ms = 75,
-- 	target = "CursorColor",
-- }
--
-- -- ── Keys ────────────────────────────────────────────────────────────
-- local mod = is_darwin and "CMD" or "CTRL|SHIFT"
--
-- config.keys = {
-- 	{ key = "t", mods = mod, action = wezterm.action.SpawnTab("CurrentPaneDomain") },
-- 	{ key = "w", mods = mod, action = wezterm.action.CloseCurrentTab({ confirm = false }) },
-- 	{ key = "d", mods = mod, action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
-- 	{ key = "d", mods = mod .. "|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
-- 	{ key = "h", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Left") },
-- 	{ key = "l", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Right") },
-- 	{ key = "k", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Up") },
-- 	{ key = "j", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Down") },
-- 	{ key = "=", mods = mod, action = wezterm.action.IncreaseFontSize },
-- 	{ key = "-", mods = mod, action = wezterm.action.DecreaseFontSize },
-- 	{ key = "0", mods = mod, action = wezterm.action.ResetFontSize },
-- 	{ key = "c", mods = mod, action = wezterm.action.CopyTo("Clipboard") },
-- 	{ key = "v", mods = mod, action = wezterm.action.PasteFrom("Clipboard") },
-- 	{ key = "w", mods = mod .. "|ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
-- }
--
-- return config
--

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local is_darwin = wezterm.target_triple:find("darwin") ~= nil
local function is_windows()
  return package.config:sub(1, 1) == "\\" or os.getenv("OS") == "Windows_NT"
end

if is_windows() then
  config.default_prog = { "pwsh.exe" }
end

-- ── Font ────────────────────────────────────────────────────────────
config.font = wezterm.font("Cascadia Code NF", { weight = "Regular" })

if is_darwin then
  config.font_size = 20
end

config.font_rules = {
  {
    intensity = "Bold",
    italic = false,
    font = wezterm.font("Cascadia Code NF", { weight = "Bold" }),
  },
}
config.harfbuzz_features =
  { "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08", "ss19", "ss20", "liga", "calt" }
config.line_height = 1.1

-- ── Appearance ──────────────────────────────────────────────────────
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

-- ── Tab bar ─────────────────────────────────────────────────────────
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32

-- ── Cursor ──────────────────────────────────────────────────────────
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- ── Bell ────────────────────────────────────────────────────────────
config.audible_bell = "Disabled"

-- ── Right status ────────────────────────────────────────────────────
wezterm.on("update-right-status", function(window, pane)
  local workspace = window:active_workspace()
  local time = wezterm.strftime("%H:%M")
  local date = wezterm.strftime("%a %d")
  window:set_right_status(wezterm.format({
    { Foreground = { AnsiColor = "Fuchsia" } },
    { Text = "  " .. workspace .. " " },
    { Foreground = { AnsiColor = "Silver" } },
    { Text = " " .. date .. " " .. time .. " " },
  }))
end)

-- ── Leader ──────────────────────────────────────────────────────────
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
  -- ── Pane splits ─────────────────────────────────────────────────
  { key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- ── Pane navigation ─────────────────────────────────────────────
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

  -- ── Pane resize ─────────────────────────────────────────────────
  { key = "H", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "L", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "K", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "J", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },

  -- ── Pane zoom ───────────────────────────────────────────────────
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

  -- ── Pane close ──────────────────────────────────────────────────
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },

  -- ── Tabs ────────────────────────────────────────────────────────
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "X", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = ",", mods = "LEADER", action = act.MoveTabRelative(-1) },
  { key = ".", mods = "LEADER", action = act.MoveTabRelative(1) },
  {
    key = "r",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "Rename tab",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },

  -- ── Workspaces ──────────────────────────────────────────────────
  {
    key = "w",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "Switch/Create workspace",
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
        end
      end),
    }),
  },
  { key = "W", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
  { key = "n", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
  { key = "p", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
  { key = "f", mods = "LEADER", action = act.ShowLauncher },
  { key = "P", mods = "LEADER", action = act.ActivateCommandPalette },

  -- ── Copy mode ───────────────────────────────────────────────────
  { key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
  { key = "Space", mods = "LEADER", action = act.QuickSelect },

  -- ── Scrolling and buffer management ─────────────────────────────
  { key = "u", mods = "LEADER", action = act.ScrollByPage(-0.5) },
  { key = "d", mods = "LEADER", action = act.ScrollByPage(0.5) },
  { key = "l", mods = "LEADER|CTRL", action = act.ClearScrollback("ScrollbackAndViewport") },

  -- ── Pane movement ───────────────────────────────────────────────
  { key = "{", mods = "LEADER", action = act.RotatePanes("CounterClockwise") },
  { key = "}", mods = "LEADER", action = act.RotatePanes("Clockwise") },

  -- ── Font size ───────────────────────────────────────────────────
  { key = "=", mods = "LEADER", action = act.IncreaseFontSize },
  { key = "-", mods = "LEADER", action = act.DecreaseFontSize },
  { key = "0", mods = "LEADER", action = act.ResetFontSize },

  -- ── Clipboard (keep OS shortcuts for these, too essential) ──────
  { key = "c", mods = is_darwin and "CMD" or "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = is_darwin and "CMD" or "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
}

config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 10000

return config

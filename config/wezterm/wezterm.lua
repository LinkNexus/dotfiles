local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local is_darwin = wezterm.target_triple:find("darwin") ~= nil
local function is_windows()
  return package.config:sub(1, 1) == "\\" or os.getenv("OS") == "Windows_NT"
end
local font_name = "FiraCode Nerd Font"

if is_windows() then
  config.default_prog = { "pwsh.exe" }
  config.default_prog = { "pwsh.exe" }
end

-- ── Font ────────────────────────────────────────────────────────────
config.font = wezterm.font(font_name, { weight = "Medium" })

if is_darwin then
  config.font_size = 20
elseif is_windows() then
  config.font_size = 13
end

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

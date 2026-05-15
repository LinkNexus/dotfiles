local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local is_darwin = wezterm.target_triple:find("darwin") ~= nil
local is_windows = wezterm.target_triple:find("windows") ~= nil

local font_name = "MonaspiceRn Nerd Font"

if is_windows then
	config.default_prog = { "pwsh.exe" }
end

config.font = wezterm.font(font_name, { weight = "Medium" })
config.font_size = is_darwin and 18.5 or 13

config.harfbuzz_features = { "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08", "ss09", "ss10", "liga" }
config.line_height = 1.1

config.color_scheme = "carbonfox"

config.window_padding = { left = 10, right = 10, bottom = 10 }
config.window_decorations = "RESIZE|MACOS_FORCE_ENABLE_SHADOW"
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32

config.tab_bar_style = {
	new_tab = wezterm.format({
		{ Background = { Color = "transparent" } },
		{ Foreground = { Color = "#8b8b8b" } },
		{ Text = " + " },
	}),
	new_tab_hover = wezterm.format({
		{ Background = { Color = "transparent" } },
		{ Foreground = { Color = "#e8e8e8" } },
		{ Text = " + " },
	}),
}

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.window_background_opacity = 0.75
config.macos_window_background_blur = 15
config.window_frame = {
	active_titlebar_bg = "none",
	inactive_titlebar_bg = "none",
}

config.colors = {
	tab_bar = {
		background = "rgba(0, 0, 0, 0.2)",
		active_tab = {
			bg_color = "rgba(0, 0, 0, 0.3)",
			fg_color = "#e8e8e8",
			italic = false,
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "rgba(0, 0, 0, 0.1)",
			fg_color = "#8b8b8b",
		},
		inactive_tab_hover = {
			bg_color = "rgba(0, 0, 0, 0.2)",
			fg_color = "#c0c0c0",
		},
	},
}

wezterm.on("update-right-status", function(window, pane)
	local workspace = window:active_workspace()
	window:set_right_status(wezterm.format({
		{ Foreground = { AnsiColor = "Fuchsia" } },
		{ Text = "  " .. workspace .. " " },
	}))
end)

local function prompt_for_new_workspace(window, pane)
	window:perform_action(
		act.PromptInputLine({
			description = "Enter name for new workspace",
			action = wezterm.action_callback(function(window, pane, line)
				if line and line ~= "" then
					window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
		pane
	)
end

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "n", mods = "LEADER", action = wezterm.action_callback(prompt_for_new_workspace) },
	{ key = "N", mods = "LEADER", action = act.SwitchToWorkspace },
	{ key = "S", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },

	{ key = "f", mods = "LEADER", action = act.ShowLauncher },

	{ key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
	{ key = "Space", mods = "LEADER", action = act.QuickSelect },

	{ key = "u", mods = "LEADER", action = act.ScrollByPage(-0.5) },
	{ key = "d", mods = "LEADER", action = act.ScrollByPage(0.5) },
	{ key = "l", mods = "LEADER|CTRL", action = act.ClearScrollback("ScrollbackAndViewport") },

	{ key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

	{ key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },

	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },

	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "X", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = ",", mods = "LEADER", action = act.MoveTabRelative(-1) },
	{ key = ".", mods = "LEADER", action = act.MoveTabRelative(1) },
}

for i = 0, 9, 1 do
	table.insert(config.keys, {
		key = "" .. i,
		mods = "LEADER",
		action = act.ActivateTab(i),
	})
end

return config

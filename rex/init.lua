-- Rex keymap: tabs keep the usual macOS cmd chords; everything else hangs
-- off one leader (ctrl+option for now, set below), with shift for the
-- "stronger" version of a key. No prefix and no modes, so ctrl and alt
-- on their own still reach the shell and nvim.
--
-- cmd+alt and cmd+alt+shift belong to ScrollSpace/Hammerspoon, which grab
-- them system-wide before Rex sees them, so Rex binds nothing there. Its
-- own defaults on those chords never fire; unbinding them is pointless and
-- warns for every chord Rex had no default on.
-- macOS's own chords (cmd+h/m/q, cmd+shift+3/4/5, ...) are left alone.

local leader = "ctrl+alt+"

------------------------------------------------------------------------
-- Tabs
------------------------------------------------------------------------
rex.bind("cmd+t", "client.tab.new")
for i = 1, 9 do
  rex.bind("cmd+" .. i, "client.tab.goto", { index = i })
  rex.bind(leader .. i, "client.tab.goto", { index = i })
end
rex.bind(leader .. "t", "client.tab.new")
rex.bind(leader .. "shift+w", "client.tab.close")
rex.bind(leader .. "r", "client.tab.rename")
rex.bind(leader .. ",", "client.tab.previous")
rex.bind(leader .. ".", "client.tab.next")
rex.bind(leader .. "shift+,", "client.tab.move.backward")
rex.bind(leader .. "shift+.", "client.tab.move.forward")

------------------------------------------------------------------------
-- Panes
------------------------------------------------------------------------
-- cmd+w closes the focused pane, else the tab, else the window
rex.bind("cmd+w", "client.close")
rex.bind(leader .. "w", "client.close")
rex.bind(leader .. "enter", "pane.split.auto")
rex.bind(leader .. "d", "pane.split.right")
rex.bind(leader .. "shift+d", "pane.split.down")
rex.bind(leader .. "z", "pane.zoom")
rex.bind(leader .. "b", "pane.move_to_new_tab")
rex.bind(leader .. "=", "pane.balance")

-- Floating panes
rex.bind(leader .. "f", "pane.float")
rex.bind(leader .. "o", "pane.new_floating")
rex.bind(leader .. "m", "pane.minimize_floating")
rex.bind(leader .. "shift+m", "pane.minimize_all_floating")

-- Arrows: focus, shift moves the pane, cmd resizes it; [ ] cycle panes
for _, direction in ipairs({ "left", "down", "up", "right" }) do
  rex.bind(leader .. direction, "pane.focus", { direction = direction })
  rex.bind(leader .. "shift+" .. direction, "pane.move", { direction = direction })
  rex.bind(leader .. "cmd+" .. direction, "pane.resize", { direction = direction, amount = 5 })
end
rex.bind(leader .. "[", "pane.focus_previous")
rex.bind(leader .. "]", "pane.focus_next")

------------------------------------------------------------------------
-- Misc
------------------------------------------------------------------------
-- The session picker moves off cmd+k, which clears the terminal as in
-- Terminal.app, iTerm2 and Ghostty
rex.bind(leader .. "k", "session.switch")
rex.bind("cmd+k", "com.superlogical.terminal.clear")
rex.bind(leader .. "shift+r", "client.config.reload")

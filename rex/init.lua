-- Rex keymap: plain cmd and cmd+shift chords, no prefix and no modes, so
-- every ctrl and alt key reaches the shell and nvim untouched.
--
-- cmd+alt and cmd+alt+shift belong to ScrollSpace/Hammerspoon, which grab
-- them system-wide before Rex sees them, so Rex binds nothing there and
-- drops whatever defaults it had on them (bottom of this file).
-- macOS's own chords (cmd+h/m/q, cmd+shift+3/4/5, ...) are left alone.

------------------------------------------------------------------------
-- Tabs
------------------------------------------------------------------------
rex.bind("cmd+t", "client.tab.new")
rex.bind("cmd+shift+w", "client.tab.close")
rex.bind("cmd+shift+r", "client.tab.rename")
rex.bind("cmd+shift+[", "client.tab.previous")
rex.bind("cmd+shift+]", "client.tab.next")
rex.bind("cmd+shift+,", "client.tab.move.backward")
rex.bind("cmd+shift+.", "client.tab.move.forward")
for i = 1, 9 do
  rex.bind("cmd+" .. i, "client.tab.goto", { index = i })
end

------------------------------------------------------------------------
-- Panes
------------------------------------------------------------------------
-- cmd+w closes the focused pane, else the tab, else the window
rex.bind("cmd+w", "client.close")
rex.bind("cmd+enter", "pane.split.auto")
rex.bind("cmd+d", "pane.split.right")
rex.bind("cmd+shift+d", "pane.split.down")
rex.bind("cmd+shift+enter", "pane.zoom")
rex.bind("cmd+shift+b", "pane.move_to_new_tab")
rex.bind("ctrl+cmd+=", "pane.balance")

-- Floating panes. cmd+shift+n stays Rex's New Session.
rex.bind("cmd+shift+f", "pane.float")
rex.bind("cmd+shift+o", "pane.new_floating")
rex.bind("cmd+shift+m", "pane.minimize_floating")

-- Focus: hjkl, plus cmd+[ / cmd+] to cycle
rex.bind("cmd+shift+h", "pane.focus", { direction = "left" })
rex.bind("cmd+shift+j", "pane.focus", { direction = "down" })
rex.bind("cmd+shift+k", "pane.focus", { direction = "up" })
rex.bind("cmd+shift+l", "pane.focus", { direction = "right" })
rex.bind("cmd+[", "pane.focus_previous")
rex.bind("cmd+]", "pane.focus_next")

-- Resize with ctrl+cmd, move with ctrl+cmd+shift, both on hjkl
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+cmd+" .. key, "pane.resize", { direction = direction, amount = 5 })
  rex.bind("ctrl+cmd+shift+" .. key, "pane.move", { direction = direction })
end

------------------------------------------------------------------------
-- Misc
------------------------------------------------------------------------
rex.bind("ctrl+cmd+,", "client.config.reload")

------------------------------------------------------------------------
-- Keep off ScrollSpace's and Hammerspoon's chords (hammerspoon/init.lua)
------------------------------------------------------------------------
local taken = {
  "left", "right", "up", "down", "escape", ",", "`",
  "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "b", "c", "d", "e", "f", "i", "o", "q", "r", "s", "t",
}
for _, key in ipairs(taken) do
  rex.unbind("cmd+alt+" .. key)
  rex.unbind("cmd+alt+shift+" .. key)
end

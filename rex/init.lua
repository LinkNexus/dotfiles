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
rex.bind(leader .. "s", "pane.split.auto")
rex.bind(leader .. "d", "pane.split.right")
rex.bind(leader .. "shift+d", "pane.split.down")
-- Maximize the pane in its tab, and back
rex.bind(leader .. "enter", "pane.zoom")
rex.bind(leader .. "n", "pane.rename")
rex.bind(leader .. "b", "pane.move_to_new_tab")
rex.bind(leader .. "=", "pane.balance")

-- Floating panes
-- Float a tiled pane, or tile a floating one back
rex.bind(leader .. "shift+enter", "pane.float")
rex.bind(leader .. "o", "pane.new_floating")
rex.bind(leader .. "m", "pane.minimize_floating")
rex.bind(leader .. "shift+m", "pane.minimize_all_floating")

-- Shelved 2026-11-20: a picker for which minimized pane to restore. It
-- works, but the picker is slow and the restored pane sometimes misses
-- the keyboard, which only Rex's own restore reliably gives it. Back to
-- Rex's toggle (most recent pane) until there's a proper way to restore
-- a given pane.
--
-- -- leader+m is Rex's own minimize toggle, except that with several panes
-- -- minimized it asks which one to bring back instead of taking the most
-- -- recent. Only this tab's are listed.
-- local terminal = "com.superlogical.terminal"
--
-- -- Labels are mostly a generic "shell", so describe each pane by what runs
-- -- in it: the title its program set, else the program, plus where it runs
-- local function layer_item(layer)
--   local titles, programs, cwd = {}, {}, nil
--   for _, block in ipairs(layer.blocks or {}) do
--     local title, fg
--     if block.creator_name == terminal then
--       local t = rex.block.call(terminal, "title", { block_id = block.block_id })
--       local p = rex.block.call(terminal, "process", { block_id = block.block_id })
--       title = t and t.title ~= "" and t.title or nil
--       fg = p and p.foreground
--     end
--     table.insert(titles, title or fg and fg.name or block.label or block.block_id)
--     if fg then
--       table.insert(programs, fg.name)
--       cwd = cwd or fg.cwd
--     end
--   end
--   local home = os.getenv("HOME")
--   if cwd and home and cwd:sub(1, #home) == home then
--     cwd = "~" .. cwd:sub(#home + 1)
--   end
--   local title, detail = table.concat(titles, " · "), table.concat(programs, ", ")
--   return {
--     id = layer.layer_id,
--     title = title,
--     subtitle = cwd,
--     detail = detail ~= title and detail or nil,
--     icon = "terminal",
--   }
-- end
--
-- rex.action{
--   name = "toggle_floating",
--   title = "Minimize or Restore Floating Pane…",
--   keywords = "minimized unminimize restore floating window layer",
--   run = function(ctx)
--     local view, err = rex.session.view{}
--     if not view then
--       rex.log("warn", "toggle_floating: " .. err)
--       return
--     end
--
--     local window
--     for _, w in ipairs(view.windows or {}) do
--       if w.window_id == view.active_window_id then
--         window = w
--       end
--     end
--
--     local minimized, floating_focused = {}, false
--     for _, layer in ipairs(window and window.layers or {}) do
--       if layer.state == "minimized" then
--         table.insert(minimized, layer_item(layer))
--       elseif layer.kind == "floating" then
--         for _, block in ipairs(layer.blocks or {}) do
--           floating_focused = floating_focused or block.block_id == window.focused_block_id
--         end
--       end
--     end
--
--     -- Rex's toggle minimizes the focused floating pane, else restores the
--     -- one minimized last
--     if floating_focused or #minimized < 2 then
--       rex.client.queue("pane.minimize_floating", {})
--       return
--     end
--
--     local layer_id = rex.ui.pick{
--       title = "Restore floating pane",
--       placeholder = "Filter minimized panes",
--       confirm = "Restore",
--       items = minimized,
--     }
--     if layer_id == nil then
--       return
--     end
--
--     -- Raises it and focuses its last-focused pane. Closing the picker hands
--     -- focus back to the pane it opened over a moment later, so wait that
--     -- out first; actions have no timers, hence the sleep process
--     rex.exec.start({ "/bin/sleep", "0.2" }):wait()
--     rex.session.set_layer_state{ layer_id = layer_id, state = "normal", focus = true }
--   end,
-- }
-- rex.bind(leader .. "m", "toggle_floating")

-- Dropdown panes: one floating pane per tab, found by its label, that a key
-- summons and dismisses. The first press makes it in the focused pane's
-- directory; later ones minimize it if it has focus, else bring it to front.
local terminal = "com.superlogical.terminal"

local function dropdown(label, bounds, options)
  return function(ctx)
    local view, err = rex.session.view{}
    if not view then
      rex.log("warn", label .. ": " .. err)
      return
    end
    local window
    for _, w in ipairs(view.windows or {}) do
      if w.window_id == view.active_window_id then
        window = w
      end
    end
    if not window then
      return
    end

    for _, layer in ipairs(window.layers or {}) do
      if layer.kind == "floating" then
        local mine, focused = false, false
        for _, block in ipairs(layer.blocks or {}) do
          mine = mine or block.label == label
          focused = focused or block.block_id == window.focused_block_id
        end
        if mine then
          if focused and layer.state ~= "minimized" then
            rex.session.set_layer_state{ layer_id = layer.layer_id, state = "minimized" }
          else
            rex.session.set_layer_state{ layer_id = layer.layer_id, state = "normal", focus = true }
          end
          return
        end
      end
    end

    local cwd
    local p = rex.block.call(terminal, "process", { block_id = window.focused_block_id })
    cwd = p and p.foreground and p.foreground.cwd
    local opts = { cwd = cwd }
    for k, v in pairs(options or {}) do
      opts[k] = v
    end
    rex.session.new_layer{
      window_id = window.window_id,
      bounds = bounds,
      layout = { block = { flavor = terminal .. ".shell", label = label, options = opts } },
      focus = true,
    }
  end
end

rex.action{
  name = "scratch_terminal",
  title = "Toggle Scratch Terminal",
  keywords = "dropdown quake floating shell terminal",
  run = dropdown("scratch", { 0.2, 0.2, 0.6, 0.6 }),
}
rex.bind(leader .. "`", "scratch_terminal")

rex.action{
  name = "lazygit",
  title = "Toggle Lazygit",
  keywords = "dropdown floating git",
  -- Quitting lazygit closes the pane, so the next press starts it afresh
  run = dropdown("lazygit", { 0.05, 0.05, 0.9, 0.9 }, { command = { "lazygit" } }),
}
rex.bind(leader .. "g", "lazygit")

-- yazi belongs to the tab, not to an editor: its edit opener runs
-- scripts/rex-open, which asks open_in_editor below where the files go
rex.action{
  name = "yazi",
  title = "Toggle Yazi",
  keywords = "dropdown floating file manager explorer",
  run = dropdown("yazi", { 0.05, 0.05, 0.9, 0.9 }, { command = { "yazi" } }),
}
rex.bind(leader .. "e", "yazi")

-- The editors open_in_editor can hand files to, by the name of the
-- foreground process in their pane
local editors = { nvim = true, vim = true }

local function editor_item(block, fg)
  local t = rex.block.call(terminal, "title", { block_id = block.block_id })
  local cwd = fg.cwd
  local home = os.getenv("HOME")
  if cwd and home and cwd:sub(1, #home) == home then
    cwd = "~" .. cwd:sub(#home + 1)
  end
  return {
    id = block.block_id,
    editor = fg.name,
    title = t and t.title ~= "" and t.title or fg.name,
    subtitle = cwd,
    detail = fg.name,
    icon = "code",
  }
end

-- Run by scripts/rex-open from the yazi pane. Finds the editors in yazi's
-- tab and, with several, asks which one gets the files. It only decides:
-- the script does the opening, hiding and focusing, since handing files
-- to nvim takes nvim's own client. Returns the chosen pane and editor, or
-- none, plus what the script needs to hide yazi or split for a new nvim.
rex.action{
  name = "open_in_editor",
  title = "Pick Editor for Yazi",
  keywords = "yazi open file nvim vim",
  run = function(ctx)
    local view, err = rex.session.view{}
    if not view then
      error("open_in_editor: " .. err)
    end

    local window, own_layer
    for _, w in ipairs(view.windows or {}) do
      for _, layer in ipairs(w.layers or {}) do
        for _, block in ipairs(layer.blocks or {}) do
          if block.block_id == ctx.block_id then
            window, own_layer = w, layer
          end
        end
      end
    end
    if not window then
      error("open_in_editor: run it from a pane in a tab")
    end

    local items, anchor = {}, nil
    for _, layer in ipairs(window.layers) do
      if layer.kind == "tiled" then
        anchor = layer.blocks[1] and layer.blocks[1].block_id
      end
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id ~= ctx.block_id and block.creator_name == terminal then
          local p = rex.block.call(terminal, "process", { block_id = block.block_id })
          local fg = p and p.foreground
          if fg and editors[fg.name] then
            table.insert(items, editor_item(block, fg))
          end
        end
      end
    end

    local result = {
      session_id = view.session_id,
      own_layer = own_layer.kind == "floating" and own_layer.layer_id or nil,
      anchor = anchor,
    }
    local chosen
    if #items == 1 then
      chosen = items[1]
    elseif #items > 1 then
      local id = rex.ui.pick{
        title = "Open in which editor?",
        placeholder = "Filter editors",
        confirm = "Open",
        items = items,
      }
      if id == nil then
        result.cancelled = true
        return result
      end
      for _, item in ipairs(items) do
        if item.id == id then
          chosen = item
        end
      end
      result.picked = true
    end
    if chosen then
      result.block_id, result.editor = chosen.id, chosen.editor
    end
    return result
  end,
}

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
rex.bind(leader .. "shift+k", "session.rename")
rex.bind(leader .. "p", "client.palette.toggle")
rex.bind("cmd+k", "com.superlogical.terminal.clear")
rex.bind(leader .. "shift+r", "client.config.reload")

-- Native hs.menubar fallback for sketchybar/items/scrollspace.lua's
-- workspace pills, for whenever sketchybar is off. on-display-change
-- stops sketchybar below MIN_WIDTH (built-in-screen-only setups --
-- notch/menu bar height eat too much of that screen for it to be
-- useful), which meant no workspace indicator at all on the built-in
-- screen. hs.menubar items are real macOS menu bar items, so unlike
-- sketchybar's overlay they're automatically notch-aware -- no
-- positioning fight needed, and setMenu()'s click handling is native
-- and reliable (sketchybar's own pill click-to-switch never worked
-- out this session -- see items/scrollspace.lua's still-unresolved
-- click_script diagnostic).
--
-- Rebuild triggers: ScrollSpace.state.onChange() for workspace/window
-- changes (same hook scrollspace-sketchybar.lua uses), plus a 5s poll
-- since sketchybar starting/stopping (on-display-change, driven off
-- screen connect/disconnect) isn't a ScrollSpace state change at all --
-- same poll-safety-net reasoning the original paperwm-sketchybar.lua
-- used for its own external, non-ScrollSpace-state trigger.

local item = nil

local function isSketchybarRunning()
  local _, ok = hs.execute('pgrep -xq sketchybar')
  return ok == true
end

local function appNamesForWorkspace(workspace)
  local apps = {}

  for _, column in ipairs(ScrollSpace.state.windowList(workspace)) do
    for _, window in ipairs(column) do
      local app = window:application()
      table.insert(apps, app and app:name() or '?')
    end
  end

  for id, floatingWorkspace in pairs(ScrollSpace.state.is_floating) do
    if floatingWorkspace == workspace then
      local window = hs.window.get(id)
      if window then
        local app = window:application()
        table.insert(apps, app and app:name() or '?')
      end
    end
  end

  return apps
end

local function rebuild()
  if isSketchybarRunning() then
    if item then
      item:delete()
      item = nil
    end
    return
  end

  if not item then
    item = hs.menubar.new()
  end
  if not item then return end -- menu bar out of space; nothing to do

  local current = ScrollSpace.state.current_workspace
  local currentApps = appNamesForWorkspace(current)
  item:setTitle(tostring(current) .. (#currentApps > 0 and (': ' .. table.concat(currentApps, ', ')) or ''))

  local menu = {}
  for _, workspace in ipairs(ScrollSpace.state.allWorkspaces()) do
    local apps = appNamesForWorkspace(workspace)
    if #apps > 0 or workspace == current then
      table.insert(menu, {
        title = tostring(workspace) .. (#apps > 0 and (': ' .. table.concat(apps, ', ')) or ' (empty)'),
        checked = workspace == current,
        fn = function() ScrollSpace.workspace.switchWorkspace(workspace) end,
      })
    end
  end
  item:setMenu(menu)
end

ScrollSpace.state.onChange(rebuild)
local poller = hs.timer.doEvery(5, rebuild)
rebuild() -- draw the initial state immediately, don't wait for the first change/poll

return { rebuild = rebuild, poller = poller }

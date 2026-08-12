-- Feeds sketchybar/items/paperwm.lua, replacing what
-- scripts/paneru-subscribe + `paneru query virtual-workspaces --json`
-- used to provide. PaperWM has no daemon/CLI to query -- it runs inside
-- this Hammerspoon process -- so instead of a subprocess forwarding a
-- socket stream, this module builds the same "space -> windows -> app
-- names" shape itself and writes it to STATE_FILE, then tells sketchybar
-- to re-read it.
--
-- STATE_FILE is a plain line format, not JSON: sketchybar's Lua side
-- (SbarLua) has no general-purpose JSON decoder exposed to Lua (only an
-- internal one it uses for its own --query replies), and hand-rolling
-- one on that side for a shape this simple isn't worth it. One line per
-- nonempty space: "<number> <spaceID> <active 0/1> <app1>|<app2>|...".
--
-- hs.spaces.windowsForSpace(id) returns window IDs for every window on
-- a space, including background/helper windows Hammerspoon can't resolve
-- to an app (confirmed live: most IDs it returns come back nil from
-- hs.window.get). PaperWM.window_filter:getWindows() is the reverse --
-- clean, named, tileable windows, but with no space info attached. This
-- cross-references the two: real windows whose ID shows up in a space's
-- ID set belong to that space.
--
-- Space numbering matches PaperWM's own switch_space_N/move_window_N --
-- position within hs.spaces.spacesForScreen(screen), 1-indexed. Scoped
-- to hs.screen.mainScreen() only: sketchybar's pills live on one bar on
-- one screen, and Paneru's own workspace numbers were already "rows
-- stacked per-monitor" rather than portable across displays, so this
-- isn't a new limitation.

local STATE_FILE = '/tmp/paperwm-state.txt'
local HOOK_PATH = '/run/current-system/sw/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'

local function notifySketchybar()
  local cmd = string.format('export PATH="%s"; sketchybar --trigger paperwm_workspace_change', HOOK_PATH)
  hs.task.new('/bin/sh', nil, { '-c', cmd }):start()
end

local function buildState()
  local screen = hs.screen.mainScreen()
  local spaceIDs = hs.spaces.spacesForScreen(screen) or {}
  local activeID = hs.spaces.activeSpaces()[screen:getUUID()]

  -- windowID -> app name, real/tileable windows only (same set PaperWM
  -- itself tiles -- floating exceptions like Finder/System Settings
  -- correctly don't show up in pills, same as they didn't under Paneru)
  local windowApp = {}
  for _, w in ipairs(PaperWM.window_filter:getWindows()) do
    local app = w:application()
    windowApp[w:id()] = app and app:name() or '?'
  end

  local spaces = {}
  for i, spaceID in ipairs(spaceIDs) do
    local apps = {}
    for _, windowID in ipairs(hs.spaces.windowsForSpace(spaceID) or {}) do
      local appName = windowApp[windowID]
      if appName then
        table.insert(apps, appName)
      end
    end
    if #apps > 0 then
      table.insert(spaces, { number = i, id = spaceID, active = (spaceID == activeID), apps = apps })
    end
  end
  return spaces
end

local function writeState()
  local f = io.open(STATE_FILE, 'w')
  if f then
    for _, space in ipairs(buildState()) do
      f:write(string.format(
        '%d %d %d %s\n',
        space.number,
        space.id,
        space.active and 1 or 0,
        table.concat(space.apps, '|')
      ))
    end
    f:close()
  end
  notifySketchybar()
end

-- One space switch / window create-destroy-move produces a burst of
-- events; coalesce and act once things have settled, same pattern as
-- watchers.lua's display debounce
local pending = nil
local function scheduleUpdate()
  if pending then
    pending:stop()
  end
  pending = hs.timer.doAfter(0.3, writeState)
end

local spaceWatcher = hs.spaces.watcher.new(scheduleUpdate)
spaceWatcher:start()

local windowWatcher = hs.window.filter.default:subscribe({
  hs.window.filter.windowCreated,
  hs.window.filter.windowDestroyed,
  hs.window.filter.windowMoved,
}, scheduleUpdate)

-- Poll safety net, same reasoning as the theme/display watchers: cheap,
-- silent unless something was missed
local poller = hs.timer.doEvery(5, scheduleUpdate)

writeState() -- draw the initial state immediately, don't wait for the first change

return {
  spaceWatcher = spaceWatcher,
  windowWatcher = windowWatcher,
  poller = poller,
}

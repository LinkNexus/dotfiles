-- Feeds sketchybar/items/scrollspace.lua, replacing what
-- hammerspoon/paperwm-sketchybar.lua (deleted, see git history at
-- d6c36dc^) provided for PaperWM. That module had to cross-reference
-- hs.spaces.windowsForSpace against PaperWM.window_filter:getWindows()
-- since PaperWM had no per-space window list of its own to read.
-- ScrollSpace doesn't need that: it already owns window_list[workspace]
-- directly, so this just walks that structure straight from
-- ScrollSpace.state and writes it out.
--
-- Rebuild trigger: registered via ScrollSpace.state.onChange(), which
-- runs after every debounced State.save() write -- no independent
-- window-filter watcher or poller needed here, ScrollSpace already
-- fires that on every state-mutating action.
--
-- STATE_FILE is a plain line format, not JSON, same reasoning as the
-- PaperWM version: SbarLua has no general-purpose JSON decoder exposed
-- to Lua. One line per nonempty workspace, 3 fields (simpler than
-- PaperWM's 4 -- ScrollSpace has only one workspace-id concept, not a
-- separate real-Space id too): "<workspace> <active 0/1> <app1>|<app2>|...".

local STATE_FILE = '/tmp/scrollspace-state.txt'
local HOOK_PATH = '/run/current-system/sw/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'

local function notifySketchybar()
  local cmd = string.format('export PATH="%s"; sketchybar --trigger scrollspace_workspace_change', HOOK_PATH)
  hs.task.new('/bin/sh', nil, { '-c', cmd }):start()
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

local function writeState()
  local f = io.open(STATE_FILE, 'w')
  if f then
    for _, workspace in ipairs(ScrollSpace.state.allWorkspaces()) do
      local apps = appNamesForWorkspace(workspace)
      if #apps > 0 then
        f:write(string.format(
          '%d %d %s\n',
          workspace,
          workspace == ScrollSpace.state.current_workspace and 1 or 0,
          table.concat(apps, '|')
        ))
      end
    end
    f:close()
  end
  notifySketchybar()
end

ScrollSpace.state.onChange(writeState)
writeState() -- draw the initial state immediately, don't wait for the first change

return { writeState = writeState }

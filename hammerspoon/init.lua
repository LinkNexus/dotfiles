-- Hammerspoon owns the app-launcher hotkeys below, and, as of this trial,
-- PaperWM.spoon as well. PaperWM is being evaluated as a replacement for
-- Paneru (paneru/paneru.toml), which had reproducible bugginess/slowness
-- when debugging GUI apps from neovim. `paneru stop` was run by hand for
-- this trial (service left installed, not uninstalled) -- `paneru start`
-- brings it back if PaperWM doesn't work out. AeroSpace is still fully
-- dormant underneath both (aerospace.toml/Brewfile entries left in place
-- -- see git history for how this file looked while AeroSpace was live).
--
-- The scratchpad-style ones (kitty, btop, Finder) still branch on
-- isAeroSpaceRunning(), which is now always false in practice, so they
-- always take the Hammerspoon-native window focus/hide fallback path.
-- That branch is left in rather than deleted, purely so a revert to
-- AeroSpace doesn't require reconstructing this file from scratch.
--
-- aerospace.toml doesn't bind any of these chords -- this file is
-- their only owner, so there's no risk of both handlers firing for
-- the same keystroke.

hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
require('hs.ipc') -- lets `hs -c '...'` talk to this instance for debugging

-- Replaces scripts/theme-watcher.swift + scripts/display-watcher.swift's
-- launchd services -- see watchers.lua. Those two launchd jobs are
-- stopped (not uninstalled) so hooks don't fire twice; Makefile's
-- install-macos has the bootstrap commands to bring them back.
local watchers = require('watchers')

-- PaperWM trial -- bindings deliberately mirror paneru.toml's cmd+alt
-- hjkl leader scheme so muscle memory carries over. Not every paneru
-- binding has a PaperWM equivalent (see paneru.toml's own comments for
-- where the two models diverge); only the ones with a real analogue are
-- bound here, everything else is left at no binding rather than guessing.
PaperWM = hs.loadSpoon('PaperWM')

PaperWM.window_gap = 8 -- matches paneru.toml's 4+4 per-window padding sum

-- Mirrors paneru.toml's floating rules: System Settings and Finder never
-- tile, the kitty scratchpad title stays out of the strip so cmd+alt+i's
-- hide/show toggle above keeps working, and browser Picture-in-Picture
-- panels stay floating/sticky instead of getting pulled into a column.
PaperWM.window_filter = PaperWM.window_filter
    :setAppFilter('System Settings', false)
    :setAppFilter('Finder', false)
    :setAppFilter('kitty', { rejectTitles = 'kitty%.scratchpad' })
    :setAppFilter('Zen', { rejectTitles = 'Picture.in.[Pp]icture' })

PaperWM:bindHotkeys({
  focus_left = { { 'cmd', 'alt' }, 'left' },
  focus_right = { { 'cmd', 'alt' }, 'right' },
  focus_up = { { 'cmd', 'alt' }, 'up' },
  focus_down = { { 'cmd', 'alt' }, 'down' },
  swap_left = { { 'cmd', 'alt', 'shift' }, 'left' },
  swap_right = { { 'cmd', 'alt', 'shift' }, 'right' },
  swap_up = { { 'cmd', 'alt', 'shift' }, 'up' },
  swap_down = { { 'cmd', 'alt', 'shift' }, 'down' },
  decrease_width = { { 'cmd', 'alt' }, '-' },
  increase_width = { { 'cmd', 'alt' }, '=' },
  toggle_floating = { { 'cmd', 'alt' }, 'f' },
  focus_floating = { { 'cmd', 'alt', 'shift' }, 'f' },
  slurp_in = { { 'cmd', 'alt' }, ',' },
  barf_out = { { 'cmd', 'alt', 'shift' }, ',' },
  cycle_width = { { 'cmd', 'alt' }, 'r' },
  full_width = { { 'cmd', 'alt' }, 'return' },
  switch_space_1 = { { 'cmd', 'alt' }, '1' },
  switch_space_2 = { { 'cmd', 'alt' }, '2' },
  switch_space_3 = { { 'cmd', 'alt' }, '3' },
  switch_space_4 = { { 'cmd', 'alt' }, '4' },
  switch_space_5 = { { 'cmd', 'alt' }, '5' },
  switch_space_6 = { { 'cmd', 'alt' }, '6' },
  switch_space_7 = { { 'cmd', 'alt' }, '7' },
  switch_space_8 = { { 'cmd', 'alt' }, '8' },
  switch_space_9 = { { 'cmd', 'alt' }, '9' },
  move_window_1 = { { 'cmd', 'alt', 'shift' }, '1' },
  move_window_2 = { { 'cmd', 'alt', 'shift' }, '2' },
  move_window_3 = { { 'cmd', 'alt', 'shift' }, '3' },
  move_window_4 = { { 'cmd', 'alt', 'shift' }, '4' },
  move_window_5 = { { 'cmd', 'alt', 'shift' }, '5' },
  move_window_6 = { { 'cmd', 'alt', 'shift' }, '6' },
  move_window_7 = { { 'cmd', 'alt', 'shift' }, '7' },
  move_window_8 = { { 'cmd', 'alt', 'shift' }, '8' },
  move_window_9 = { { 'cmd', 'alt', 'shift' }, '9' },
})
PaperWM:start()

-- Feeds sketchybar/items/paperwm.lua -- needs PaperWM:start() to have
-- already configured window_filter's floating exclusions above.
local paperwmSketchybar = require('paperwm-sketchybar')

local KITTY = '/opt/homebrew/bin/kitty'
local AEROSPACE = '/opt/homebrew/bin/aerospace'
local AEROSPACE_SCRATCHPAD = '/opt/homebrew/bin/aerospace-scratchpad'
local OPEN_BTOP = os.getenv('HOME') .. '/dotfiles/scripts/open-btop'

local function isAeroSpaceRunning()
  return hs.application.get('AeroSpace') ~= nil
end

-- hs.execute always blocks the main thread until the command exits --
-- fine for instant things, but aerospace-scratchpad round-trips
-- through AeroSpace's socket and once visibly hung the entire
-- Hammerspoon event loop (every hotkey, not just this one) long enough
-- to time out its own IPC. hs.task runs the shell out-of-band instead.
local function runAsync(shellCommand)
  hs.task.new('/bin/sh', nil, { '-c', shellCommand }):start()
end

local function findWindowByTitle(title)
  for _, win in ipairs(hs.window.allWindows()) do
    if win:title() == title then
      return win
    end
  end
  return nil
end

local function findWindowByApp(appName)
  local app = hs.application.get(appName)
  return app and app:mainWindow() or nil
end

-- Mirrors aerospace-scratchpad's own show semantics (github.com/
-- cristianoliveira/aerospace-scratchpad) so the shortcut feels the same
-- whether AeroSpace is driving it or this fallback is: focus it if it's
-- not the frontmost window, otherwise put it away.
--
-- Uses app:hide()/:unhide(), not win:minimize() -- confirmed live that
-- AXMinimized is a silent no-op here (on kitty *and* native Finder
-- windows alike) whenever Stage Manager is the active window manager,
-- which is exactly the case on-display-change puts you in when
-- AeroSpace is down. hide() works reliably in that same mode. Safe to
-- hide the whole app rather than just the one window because each kitty
-- scratchpad/btop/main instance is its own separate process (confirmed
-- via hs.application.applicationsForBundleID) -- the only app this
-- shares state across windows for is Finder, where hiding puts away
-- any other Finder windows you have open too.
local function focusOrPutAway(win)
  local app = win:application()
  if app:isHidden() then
    app:unhide()
    win:focus()
  elseif win == hs.window.focusedWindow() then
    app:hide()
  else
    win:focus()
  end
end

local function toggleKittyScratchpad()
  if isAeroSpaceRunning() then
    runAsync(
      AEROSPACE_SCRATCHPAD .. " show kitty -F window-title=kitty.scratchpad || "
      .. KITTY .. " --title kitty.scratchpad"
    )
    return
  end

  local win = findWindowByTitle('kitty.scratchpad')
  if win then
    focusOrPutAway(win)
  else
    runAsync(KITTY .. ' --title kitty.scratchpad')
  end
end

local function toggleBtop()
  if isAeroSpaceRunning() then
    runAsync(AEROSPACE .. ' workspace 2 && ' .. OPEN_BTOP)
    return
  end

  local win = findWindowByTitle('kitty.btop')
  if win then
    focusOrPutAway(win)
  else
    runAsync(OPEN_BTOP)
  end
end

local function toggleFinderScratchpad()
  if isAeroSpaceRunning() then
    runAsync(AEROSPACE_SCRATCHPAD .. ' show Finder || open -a Finder')
    return
  end

  local win = findWindowByApp('Finder')
  if win then
    focusOrPutAway(win)
  else
    runAsync('open -a Finder')
  end
end

-- kitty.main is the plain daily-driver window scripts/open-login-apps
-- opens at login; unlike the scratchpad/btop windows it's never hidden,
-- just brought to front (or spawned if you've closed it).
local function focusOrSpawnMainTerminal()
  local win = findWindowByTitle('kitty.main')
  if win then
    win:focus()
  else
    runAsync(KITTY .. ' --title kitty.main')
  end
end

hs.hotkey.bind({ 'cmd', 'alt' }, 'i', toggleKittyScratchpad)
hs.hotkey.bind({ 'cmd', 'alt' }, 't', toggleBtop)
hs.hotkey.bind({ 'cmd', 'alt' }, 'e', toggleFinderScratchpad)
hs.hotkey.bind({ 'cmd', 'alt' }, 'b', function() runAsync('open -a Zen') end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'c', focusOrSpawnMainTerminal)

-- Hammerspoon owns the app-launcher hotkeys below, and, as of this trial,
-- ScrollSpace.spoon as well. ScrollSpace is a from-scratch replacement for
-- PaperWM.spoon (see hammerspoon/Spoons/ScrollSpace.spoon/CLAUDE.md for the
-- full design) -- it fixes PaperWM's column-reflow-on-hide/show problem by
-- keying tiling state to its own virtual workspace id instead of a real
-- macOS Space, and folds in workspace switching (previously FlashSpace's
-- job) and rule-based window assignment natively. PaperWM.spoon is still
-- vendored as a submodule (not removed, in case this trial doesn't work
-- out) but is no longer loaded/started; its former window_filter
-- customization here has been carried over onto ScrollSpace below.
--
-- PaperWM itself was evaluated as a replacement for Paneru
-- (paneru/paneru.toml), which had reproducible bugginess/slowness when
-- debugging GUI apps from neovim. `paneru stop` was run by hand for that
-- trial (service left installed, not uninstalled) -- `paneru start` brings
-- it back if this whole PaperWM/ScrollSpace line doesn't work out.
-- AeroSpace is still fully dormant underneath both (aerospace.toml/Brewfile
-- entries left in place -- see git history for how this file looked while
-- AeroSpace was live).
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

-- ScrollSpace trial -- bindings deliberately mirror the PaperWM trial's
-- cmd+alt hjkl leader scheme (itself carried over from paneru.toml) so
-- muscle memory keeps carrying over, including slurp_in/barf_out
-- (cmd+alt+,/cmd+alt+shift+,) for stacking a window into the column to its
-- left / popping it back out into its own column -- the way to tile
-- vertically. decrease_width/increase_width/focus_floating had no
-- ScrollSpace equivalent to bind -- see the spoon's CLAUDE.md "explicitly
-- out of scope for v1" section -- so those chords are simply unbound for
-- now rather than guessing at a replacement. New to this trial:
-- switch_workspace_1..9/move_window_1..9 (virtual workspaces) and
-- toggle_scratchpad/set_scratchpad (a single scratchpad window, unrelated
-- to the kitty/btop/Finder hide-app scratchpads below -- those are a
-- separate mechanism).
ScrollSpace = hs.loadSpoon('ScrollSpace')

ScrollSpace.window_gap = 8 -- matches paneru.toml's 4+4 per-window padding sum

-- Carried over from the PaperWM trial's own equivalent filter: System
-- Settings and Finder never tile, the kitty scratchpad title stays out of
-- the strip so cmd+alt+i's hide/show toggle below keeps working, and
-- browser Picture-in-Picture panels stay floating/sticky instead of
-- getting pulled into a column. Kept as a title-based window_filter
-- exclusion (proven to work here already) rather than relying solely on
-- ScrollSpace's own best-effort subrole-based PiP detection.
ScrollSpace.window_filter = ScrollSpace.window_filter
    :setAppFilter('System Settings', false)
    :setAppFilter('Finder', false)
    :setAppFilter('kitty', { rejectTitles = 'kitty%.scratchpad' })
    :setAppFilter('Zen', { rejectTitles = 'Picture.in.[Pp]icture' })

-- Assign windows to workspaces at creation time. Empty for now -- add
-- entries here once there's an actual multi-workspace layout in mind, e.g.
-- ScrollSpace.rules = { { app = 'kitty', title = '^btop', workspace = 2 } }

-- Copy of ScrollSpace.default_hotkeys with center_window dropped: its
-- default chord (cmd+alt+c) collides with focusOrSpawnMainTerminal below.
local scrollspace_hotkeys = {}
for action, chord in pairs(ScrollSpace.default_hotkeys) do
  if action ~= 'center_window' then
    scrollspace_hotkeys[action] = chord
  end
end
ScrollSpace:bindHotkeys(scrollspace_hotkeys)
ScrollSpace:start()

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

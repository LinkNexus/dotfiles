-- Hammerspoon owns the app-launcher hotkeys below, and, as of this trial,
-- ScrollSpace.spoon as well. ScrollSpace is a from-scratch replacement for
-- PaperWM.spoon (see hammerspoon/Spoons/ScrollSpace.spoon/CLAUDE.md for the
-- full design) -- it fixes PaperWM's column-reflow-on-hide/show problem by
-- keying tiling state to its own virtual workspace id instead of a real
-- macOS Space, and folds in workspace switching and rule-based window
-- assignment natively. PaperWM.spoon is still vendored as a submodule (not
-- removed, in case this trial doesn't work out) but is no longer
-- loaded/started; its former window_filter customization here has been
-- carried over onto ScrollSpace below.
--
-- PaperWM itself was evaluated as a replacement for Paneru
-- (paneru/paneru.toml), which had reproducible bugginess/slowness when
-- debugging GUI apps from neovim. `paneru stop` was run by hand for that
-- trial (service left installed, not uninstalled) -- `paneru start` brings
-- it back if this whole PaperWM/ScrollSpace line doesn't work out.
--
-- AeroSpace and FlashSpace are both fully retired -- no config, casks, or
-- fallback code for either remains in this repo.

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
-- to the kitty/Finder hide-app scratchpads below -- those are a
-- separate mechanism). btop used to have its own hide-app toggle here
-- too (cmd+alt+t) but that's gone now that it's a normal ScrollSpace-
-- tracked window on workspace 2 -- cmd+alt+2 is how you get to it,
-- rather than two mechanisms fighting over the same window's visibility.
ScrollSpace = hs.loadSpoon('ScrollSpace')

ScrollSpace.window_gap = 12 -- matches paneru.toml's 4+4 per-window padding sum

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

-- Assign windows to workspaces at creation time. Workspace 1: browser +
-- main terminal (daily driver). Workspace 2: mail + task manager. kitty's
-- scratchpad title is already excluded entirely by the window_filter
-- above, so it's untouched by these rules and stays on its separate
-- app-hide/unhide toggle (cmd+alt+i).
ScrollSpace.rules = {
  { app = 'kitty',       title = '^kitty%.main$', workspace = 1 },
  { app = 'Zen',         workspace = 1 },
  { app = 'kitty',       title = '^kitty%.btop$', workspace = 2 },
  { app = 'Thunderbird', workspace = 2 },
}

-- Copy of ScrollSpace.default_hotkeys with center_window dropped (its
-- default chord, cmd+alt+c, collides with focusOrSpawnMainTerminal
-- below) and toggle_scratchpad/set_scratchpad remapped off cmd+alt+s
-- (collides with Zen Browser's own sidebar toggle -- confirmed live,
-- Hammerspoon's global hotkey claims the keystroke before Zen ever
-- sees it).
local scrollspace_hotkeys = {}
for action, chord in pairs(ScrollSpace.default_hotkeys) do
  if action ~= 'center_window' then
    scrollspace_hotkeys[action] = chord
  end
end
scrollspace_hotkeys.toggle_scratchpad = { { 'cmd', 'alt' }, '`' }
scrollspace_hotkeys.set_scratchpad = { { 'cmd', 'alt', 'shift' }, '`' }
ScrollSpace:bindHotkeys(scrollspace_hotkeys)
ScrollSpace:start()

-- Feeds sketchybar/items/scrollspace.lua's workspace pills. Needs
-- ScrollSpace to already be the loaded global (reads ScrollSpace.state
-- directly) and started (writes its initial state immediately on load).
require('scrollspace-sketchybar')

-- Native menu bar fallback for whenever sketchybar is off (built-in
-- screen only -- on-display-change stops it below MIN_WIDTH). Same
-- ScrollSpace/started-global requirement as above.
require('scrollspace-menubar')

local KITTY = '/opt/homebrew/bin/kitty'

-- hs.execute always blocks the main thread until the command exits;
-- hs.task runs the shell out-of-band instead so a slow spawn can't hang
-- every other hotkey along with it.
--
-- Backgrounding the actual command with `&` (not just handing it to
-- hs.task) matters: confirmed live that hs.reload() force-kills any
-- process still tracked by an outstanding hs.task, even an unreferenced
-- one that plain Lua garbage collection alone left alone. `/bin/sh -c
-- '<single command>'` also tail-call execs directly into that command
-- with no separate child process (confirmed via ps), so for a call like
-- `kitty --title kitty.main`, the tracked process WAS kitty.main itself
-- -- every hs.reload() (including the automatic one on wake, see
-- watchers.lua) was silently killing kitty.main/kitty.scratchpad out
-- from under the user. Backgrounding makes the tracked /bin/sh exit
-- immediately after forking the real command off into its own detached
-- process, so by the time anything tries to terminate the tracked PID,
-- there's nothing left to kill.
local function runAsync(shellCommand)
  hs.task.new('/bin/sh', nil, { '-c', 'nohup ' .. shellCommand .. ' >/dev/null 2>&1 &' }):start()
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

-- Focus it if it's not the frontmost window, otherwise put it away.
--
-- Uses app:hide()/:unhide(), not win:minimize() -- confirmed live that
-- AXMinimized is a silent no-op here (on kitty *and* native Finder
-- windows alike) whenever Stage Manager is the active window manager.
-- hide() works reliably in that same mode. Safe to hide the whole app
-- rather than just the one window because each kitty scratchpad/main
-- instance is its own separate process (confirmed via
-- hs.application.applicationsForBundleID) -- the only app this
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
  local win = findWindowByTitle('kitty.scratchpad')
  if win then
    focusOrPutAway(win)
  else
    runAsync(KITTY .. ' --title kitty.scratchpad')
  end
end

local function toggleFinderScratchpad()
  local win = findWindowByApp('Finder')
  if win then
    focusOrPutAway(win)
  else
    runAsync('open -a Finder')
  end
end

-- kitty.main is the plain daily-driver window scripts/open-login-apps
-- opens at login; unlike the scratchpad windows it's never hidden, just
-- brought to front (or spawned if you've closed it).
local function focusOrSpawnMainTerminal()
  local win = findWindowByTitle('kitty.main')
  if win then
    win:focus()
  else
    runAsync(KITTY .. ' --title kitty.main')
  end
end

hs.hotkey.bind({ 'cmd', 'alt' }, 'i', toggleKittyScratchpad)
hs.hotkey.bind({ 'cmd', 'alt' }, 'e', toggleFinderScratchpad)
hs.hotkey.bind({ 'cmd', 'alt' }, 'b', function() runAsync('open -a Zen') end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'c', focusOrSpawnMainTerminal)

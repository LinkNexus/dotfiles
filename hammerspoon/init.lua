-- Hammerspoon exists specifically to own the app-launcher hotkeys below.
-- scripts/on-display-change fully quits AeroSpace on the laptop screen
-- (see that script for why disabling alone wasn't enough), which means
-- AeroSpace's own key bindings disappear entirely in that mode, not
-- just stop tiling. Hammerspoon runs as its own always-on daemon
-- independent of AeroSpace/Stage Manager, so it's the one layer that
-- can offer the same shortcuts in both modes.
--
-- The scratchpad-style ones (kitty, btop, Finder) branch on whether
-- AeroSpace is currently up: when it is, they lean on
-- aerospace-scratchpad/AeroSpace's own workspace commands; when it
-- isn't, they fall back to Hammerspoon's own window focus/minimize,
-- since there's no workspace concept once Stage Manager takes over.
--
-- aerospace.toml doesn't bind any of these chords -- this file is
-- their only owner, so there's no risk of both handlers firing for
-- the same keystroke while AeroSpace is running.

hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(false)
require('hs.ipc') -- lets `hs -c '...'` talk to this instance for debugging

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

-- Called from scripts/on-display-change (via `hs -c`) at the exact
-- moment it switches to the built-in screen -- windows don't get
-- repositioned on that transition, they just keep whatever size/
-- position they had while tiled on the external monitor, which reads
-- as tiny/misplaced on the laptop screen. Fills each standard window
-- (isStandard() excludes dialogs/panels) to its own screen. One-shot,
-- not an ongoing policy -- doesn't touch windows you open afterwards.
--
-- Global (not local) so the shell script can reach it through the IPC
-- CLI. Originally tried an hs.application.watcher on AeroSpace's
-- `terminated` event instead, but confirmed live that watcher never
-- fires for AeroSpace at all -- it's a Dock-icon-less accessory app and
-- doesn't emit the NSWorkspace notifications the watcher relies on
-- (a plain app like Calculator fires them fine). Driving this from
-- on-display-change directly is more precise anyway: it's the one
-- place that already knows the transition happened, no polling needed.
function maximizeAllStandardWindows()
  for _, win in ipairs(hs.window.allWindows()) do
    if win:isStandard() then
      win:maximize()
    end
  end
end

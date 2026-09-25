-- Hammerspoon-native replacements for scripts/theme-watcher.swift and
-- scripts/display-watcher.swift's launchd services. Ran side-by-side as
-- a logging-only prototype first (see git history) to confirm Hammerspoon
-- doesn't miss theme/display events around sleep-wake the way a bare
-- background LaunchAgent did; now graduated to calling the real hooks.
-- The two launchd services are stopped (`launchctl bootout`, not
-- uninstalled -- see Makefile's install-macos for the bootstrap
-- commands to bring them back) so hooks don't fire twice.
--
-- hs.caffeinate.watcher's wake events are the one piece with no Swift
-- equivalent -- the Swift watchers approximated "did we miss anything
-- across sleep" with blind 10s/30s polling; this fires an immediate
-- recheck right on wake instead.

local DOTFILES = os.getenv('HOME') .. '/dotfiles'
local ON_THEME_CHANGE = DOTFILES .. '/scripts/on-theme-change'
local ON_DISPLAY_CHANGE = DOTFILES .. '/scripts/on-display-change'

-- Both hooks shell out to tmux/sketchybar/borders/paneru by bare name.
-- Hammerspoon's own PATH is the bare macOS default (/usr/bin:/bin:
-- /usr/sbin:/sbin -- confirmed via `hs -c 'hs.execute("echo $PATH")'`),
-- same gap the launchd plists worked around with an explicit PATH.
local HOOK_PATH = '/run/current-system/sw/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'

local function logTo(path, msg)
  local f = io.open(path, 'a')
  if f then
    f:write(os.date('%Y-%m-%d %H:%M:%S') .. ' ' .. msg .. '\n')
    f:close()
  end
end

-- Non-zero exits land here; on-display-change already keeps its own
-- /tmp/display-watcher.log for the successful-run detail.
local function runHook(logPath, scriptPath, extraArgs)
  local cmd = string.format('export PATH="%s"; "%s"%s', HOOK_PATH, scriptPath, extraArgs and (' ' .. extraArgs) or '')
  hs.task.new('/bin/sh', function(exitCode, _, stdErr)
    if exitCode ~= 0 then
      logTo(logPath, string.format('%s exited %d: %s', scriptPath, exitCode, stdErr))
    end
  end, { '-c', cmd }):start()
end

-- ── Theme watcher ──────────────────────────────────────────────
local THEME_LOG = '/tmp/hs-theme-watcher.log'

local function currentStyle()
  local style = hs.execute('defaults read -g AppleInterfaceStyle 2>/dev/null')
  style = style:gsub('%s+$', '')
  return style == 'Dark' and 'Dark' or 'Light'
end

local lastStyle = currentStyle()

local function checkTheme(source)
  local style = currentStyle()
  if style ~= lastStyle then
    lastStyle = style
    runHook(THEME_LOG, ON_THEME_CHANGE)
  end
end

local themeNotifier = hs.distributednotifications.new(function()
  checkTheme('distributed-notification')
end, 'AppleInterfaceThemeChangedNotification')
themeNotifier:start()

local themePoller = hs.timer.doEvery(30, function() checkTheme('poll') end)

logTo(THEME_LOG, 'watcher (re)started, initial style = ' .. lastStyle)

-- ── Display watcher ────────────────────────────────────────────
local DISPLAY_LOG = '/tmp/hs-display-watcher.log'

local function widestScreen()
  local max = 0
  for _, screen in ipairs(hs.screen.allScreens()) do
    local w = screen:fullFrame().w
    if w > max then max = w end
  end
  return max
end

local lastWidth = widestScreen()
local displayDebounce = nil

local function checkDisplay(source)
  local width = widestScreen()
  if width ~= lastWidth then
    lastWidth = width
    runHook(DISPLAY_LOG, ON_DISPLAY_CHANGE)
  end
end

-- Mirrors display-watcher.swift's 1.5s coalescing: one plug/unplug fires a
-- burst of screen-watcher callbacks, only act once things settle
local function scheduleDisplayCheck(source)
  if displayDebounce then
    displayDebounce:stop()
  end
  displayDebounce = hs.timer.doAfter(1.5, function() checkDisplay(source) end)
end

local screenWatcher = hs.screen.watcher.new(function()
  scheduleDisplayCheck('screen-watcher')
end)
screenWatcher:start()

local displayPoller = hs.timer.doEvery(10, function() checkDisplay('poll') end)

logTo(DISPLAY_LOG, 'watcher (re)started, initial widest = ' .. lastWidth .. 'pt')

-- Reconcile once on (re)load, same as display-watcher.swift's own
-- startup call, so a fresh login/reload lands in the right state.
runHook(DISPLAY_LOG, ON_DISPLAY_CHANGE)

-- ── Reload-on-return safety net ────────────────────────────────
-- macOS can silently disable Hammerspoon's global hotkeys, both after
-- sleep and after a long idle stretch at the desk with no sleep at all
-- (the "no console error, it just stops responding" bug,
-- github.com/Hammerspoon/hammerspoon/issues/3294). Hammerspoon neither
-- detects nor recovers from this on its own, so hotkeys stay dead until
-- something re-registers them; hs.reload() does that, and is exactly the
-- manual workaround that has been fixing it by hand.
--
-- The hard-won part is *when* to reload: never while the user is away.
-- Confirmed from the Hammerspoon console log (2026-09-24): every
-- automatic reload up to this point fired while `loginwindow` owned the
-- session -- i.e. at the lock screen -- and every reload that actually
-- restored working hotkeys was a manual one, unlocked. A reload at the
-- lock screen re-runs this whole config, ScrollSpace:start() included,
-- against an accessibility subsystem that cannot see other apps' windows
-- while loginwindow is up: State.load()/refreshWindows() reconcile the
-- layout against an effectively empty world, and the debounced
-- State.save() then writes that empty result over the good snapshot.
-- Hotkeys re-registered in that context log as "Enabled" but are not
-- reliably live once the session comes back either. Both match the
-- reported symptom -- ScrollSpace bindings dead after sleep or
-- inactivity until Hammerspoon is reloaded by hand.
--
-- So: reload when the user *returns*, never while they are gone. Every
-- trigger funnels through requestReload(), which fires immediately when
-- the session is actually usable and otherwise defers to the next
-- unlock/wake. reload() also re-runs the theme/display checks above from
-- scratch (currentStyle()/widestScreen() are recomputed at load time),
-- so calling checkTheme/scheduleDisplayCheck directly on wake would be
-- redundant.
local RELOAD_LOG = '/tmp/hs-reload.log'
local IDLE_THRESHOLD = 600 -- 10 minutes away before a reload is worth it

-- hs.caffeinate has no lock-state predicate; CGSSessionScreenIsLocked is
-- absent from sessionProperties() entirely while unlocked and present
-- and true at the lock screen.
local function sessionLocked()
  local props = hs.caffeinate.sessionProperties() or {}
  return props.CGSSessionScreenIsLocked == true
end

-- Screen sleep has no polled equivalent either, so track it off the
-- watcher events below.
local screensAsleep = false
local pendingReload = false
local reloadDebounce = nil

local function sessionUsable()
  return not screensAsleep and not sessionLocked()
end

-- Debounced: one wake fires several of the events below, and the idle
-- poller can land in the same moment -- one reload covers them all.
local function requestReload(reason)
  if not sessionUsable() then
    if not pendingReload then
      logTo(RELOAD_LOG, 'deferring reload (' .. reason .. '): screens asleep or session locked')
    end
    pendingReload = true
    return
  end

  if reloadDebounce then
    reloadDebounce:stop()
  end
  logTo(RELOAD_LOG, 'reloading: ' .. reason)
  -- pendingReload is deliberately not cleared: hs.reload() wipes all Lua
  -- state a second later, which clears it far more thoroughly.
  reloadDebounce = hs.timer.doAfter(1, function() hs.reload() end)
end

local caffeinate = hs.caffeinate.watcher

-- Anything that means "the user may be back". screensDidWake usually
-- still lands at the lock screen and simply defers; the screensDidUnlock
-- or sessionDidBecomeActive that follows is what actually reloads. On a
-- machine that never locks, screensDidWake reloads directly.
local RETURN_EVENTS = {
  [caffeinate.systemDidWake] = 'systemDidWake',
  [caffeinate.screensDidWake] = 'screensDidWake',
  [caffeinate.screensDidUnlock] = 'screensDidUnlock',
  [caffeinate.sessionDidBecomeActive] = 'sessionDidBecomeActive',
  [caffeinate.screensaverDidStop] = 'screensaverDidStop',
}

local wakeWatcher = caffeinate.new(function(event)
  -- keep the sleep flag current before anything consults sessionUsable()
  if event == caffeinate.screensDidSleep then
    screensAsleep = true
  elseif event == caffeinate.screensDidWake then
    screensAsleep = false
  end

  local reason = RETURN_EVENTS[event]
  if reason then
    requestReload(reason)
  end
end)
wakeWatcher:start()

-- The no-sleep, no-lock case: the machine just sits idle at the desk and
-- the tap dies with no caffeinate event ever firing. idleTime() dropping
-- between two samples means real input happened, i.e. the user is back --
-- reload on that transition only, and only if they had been gone long
-- enough for the tap to plausibly have died.
--
-- This replaces an earlier "reload while idle, throttled by a cooldown
-- persisted to /tmp" approach. That one could not distinguish "still
-- away" from "back", so it just re-fired every 25 minutes for as long as
-- the machine stayed idle -- 14 reloads over one night, every one of
-- them at the lock screen, every one a chance to overwrite ScrollSpace's
-- persisted layout with an empty one. Reacting to the return transition
-- needs no cooldown and no persisted state: the reload it triggers wipes
-- lastIdle along with everything else, and the next sample starts from a
-- fresh, small idle time.
local lastIdle = hs.host.idleTime()

local idlePoller = hs.timer.doEvery(30, function()
  local idle = hs.host.idleTime()
  if lastIdle > IDLE_THRESHOLD and idle < lastIdle then
    requestReload(string.format('back after %ds idle', math.floor(lastIdle)))
  end
  lastIdle = idle
end)


-- Returned (and required from init.lua into a local) purely so these
-- watcher objects stay referenced and don't get garbage collected --
-- require() caching in package.loaded already does this, but a caller
-- holding the return value is not relying on that implementation detail.
return {
  themeNotifier = themeNotifier,
  themePoller = themePoller,
  screenWatcher = screenWatcher,
  displayPoller = displayPoller,
  wakeWatcher = wakeWatcher,
  idlePoller = idlePoller,
}

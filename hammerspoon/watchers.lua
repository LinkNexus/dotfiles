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

-- ── Wake safety net for both, plus hotkey-recovery reload ───────
-- macOS can silently disable Hammerspoon's global hotkey event taps
-- after sleep or a period of screen-timeout inactivity -- Hammerspoon
-- doesn't detect or recover from this on its own, so hotkeys just go
-- dead until something re-registers them. hs.reload() does that
-- (confirmed live: this is exactly the manual workaround that's been
-- fixing it). Debounced since systemDidWake and screensDidWake both
-- fire on a full-sleep wake -- one reload covers both. reload() also
-- re-runs the theme/display checks below from scratch (currentStyle()/
-- widestScreen() are recomputed at load time), so calling checkTheme/
-- scheduleDisplayCheck directly on wake would be redundant now.
local reloadDebounce = nil
local function scheduleReload()
  if reloadDebounce then
    reloadDebounce:stop()
  end
  reloadDebounce = hs.timer.doAfter(1, function() hs.reload() end)
end

local wakeWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidWake then
    scheduleReload()
  end
end)
wakeWatcher:start()

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
}

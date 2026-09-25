-- ~/.config/sketchybar/items/scrollspace.lua
--
-- Renders one rounded "pill" (SketchyBar bracket) per ScrollSpace
-- workspace that has at least one window: a workspace number plus the
-- REAL icon of every app in it, extracted via app_icon.sh. Empty
-- workspaces get no pill.
--
-- Ported from items/paperwm.lua (see git history at d6c36dc): same
-- rebuild/bracket/theme-inversion approach, "space" renamed to
-- "workspace" throughout. hammerspoon/scrollspace-sketchybar.lua writes
-- STATE_FILE and triggers scrollspace_workspace_change on every
-- ScrollSpace state change (via ScrollSpace.state.onChange()) -- same
-- role hammerspoon/paperwm-sketchybar.lua played before, just without
-- needing its own poll safety net since ScrollSpace already fires a
-- save on every state-mutating action.
--
-- SbarLua has no "move" primitive and no way to edit an existing
-- bracket's membership, so rather than diffing against previous state,
-- every rebuild removes everything it created last time and re-adds
-- everything fresh, in order -- creation order is display order, which
-- sidesteps needing "move" at all. Wrapped in begin_config/end_config
-- so a rebuild is one atomic message to sketchybar: switching
-- workspaces should never show an empty or half-built bar.

local CONFIG_DIR = os.getenv('HOME') .. '/.config/sketchybar'
local ICON_SCRIPT = CONFIG_DIR .. '/plugins/app_icon.sh'
local STATE_FILE = '/tmp/scrollspace-state.txt'

local function shell(cmd)
  local proc = io.popen(cmd)
  if not proc then
    return nil
  end
  local out = proc:read('*l')
  proc:close()
  return out
end

local function fileExists(path)
  local f = io.open(path, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

-- Follow the OS appearance, like kitty's *-theme.auto.conf: macOS
-- reports AppleInterfaceStyle=Dark in dark mode and no key at all in
-- light mode. THEME_OVERRIDE exists for previewing the other variant.
local function isDarkTheme()
  local override = os.getenv('THEME_OVERRIDE')
  if override then
    return override == 'dark'
  end
  return shell('defaults read -g AppleInterfaceStyle 2>/dev/null') == 'Dark'
end

sbar.add('event', 'scrollspace_workspace_change')

local control = sbar.add('item', 'scrollspace_control', { drawing = false })

-- workspace number -> app count, from the last rebuild -- exactly what's
-- needed to know which item names to remove before rebuilding fresh
local previous = {}

local function rebuild()
  local f = io.open(STATE_FILE, 'r')
  if not f then
    return
  end

  local wanted = {}
  local order = {}
  for line in f:lines() do
    local workspace, active, apps = line:match('^(%d+) (%d) (.*)$')
    if workspace then
      local appList = {}
      for app in (apps .. '|'):gmatch('([^|]*)|') do
        if app ~= '' then
          table.insert(appList, app)
        end
      end
      workspace = tonumber(workspace)
      wanted[workspace] = { active = (active == '1'), apps = appList }
      table.insert(order, workspace)
    end
  end
  f:close()
  table.sort(order)

  local dark = isDarkTheme()
  -- The focused pill INVERTS the theme (light pill in dark mode and
  -- vice versa) -- maximum contrast without introducing any color
  local F_NUM, F_PILL, F_BORDER, U_NUM, U_PILL, U_BORDER
  if dark then
    F_NUM, F_PILL, F_BORDER = 0xff111111, 0xe6f5f5f7, 0x33000000
    U_NUM, U_PILL, U_BORDER = 0xff9a9aa5, 0xb314141c, 0x33ffffff
  else
    F_NUM, F_PILL, F_BORDER = 0xffffffff, 0xd91c1c26, 0x59ffffff
    U_NUM, U_PILL, U_BORDER = 0xff55555e, 0x99f2f2f5, 0x1a000000
  end

  sbar.begin_config()

  for workspace, appCount in pairs(previous) do
    sbar.remove('workspace_bracket.' .. workspace)
    sbar.remove('workspace.' .. workspace)
    sbar.remove('workspace.' .. workspace .. '.gap')
    for i = 1, appCount do
      sbar.remove('workspace.' .. workspace .. '.app' .. i)
    end
  end

  local newPrevious = {}
  local firstPill = true
  for _, workspace in ipairs(order) do
    local ws = wanted[workspace]
    local focused = ws.active
    local numColor = focused and F_NUM or U_NUM
    local pillColor = focused and F_PILL or U_PILL
    local borderColor = focused and F_BORDER or U_BORDER

    -- Invisible spacer between consecutive pills (not part of any bracket)
    if not firstPill then
      sbar.add('item', 'workspace.' .. workspace .. '.gap', {
        position = 'center',
        width = 8,
        icon = { drawing = false },
        label = { drawing = false },
        background = { drawing = false },
      })
    end
    firstPill = false

    local numberItem = sbar.add('item', 'workspace.' .. workspace, {
      position = 'center',
      icon = {
        string = tostring(workspace),
        drawing = true,
        font = 'Helvetica Neue:Bold:11.0',
        color = numColor,
        padding_left = 9,
        padding_right = 5,
      },
      label = { drawing = false },
      background = { drawing = false },
    })

    local members = { numberItem.name }
    for i, app in ipairs(ws.apps) do
      local iconPng = shell(string.format("%s '%s'", ICON_SCRIPT, app))

      -- Unfocused workspaces get the 35%-opacity variant of each icon
      if iconPng and iconPng ~= '' and not focused then
        local dim = iconPng:gsub('%.png$', '_dim.png')
        if fileExists(dim) then
          iconPng = dim
        end
      end

      local itemName = 'workspace.' .. workspace .. '.app' .. i
      local rightPad = (i == #ws.apps) and 8 or 2
      local appItem
      if iconPng and iconPng ~= '' then
        appItem = sbar.add('item', itemName, {
          position = 'center',
          icon = { drawing = false },
          label = { drawing = false },
          background = {
            image = iconPng,
            -- SbarLua flattens nested tables to dot-paths generically
            -- (parse_kv_table in its C source); "image" is also a leaf
            -- (bare path above) as well as a parent with its own
            -- sub-properties, which a normal nested Lua table can't
            -- represent -- a literal dotted key is the escape hatch.
            ['image.scale'] = 0.5,
            drawing = true,
            color = 0x00000000,
          },
          padding_left = 2,
          padding_right = rightPad,
        })
      else
        -- Extraction failed (e.g. app stores its icon in a compiled
        -- Assets.car instead of a loose .icns) -- fall back to a letter
        appItem = sbar.add('item', itemName, {
          position = 'center',
          icon = {
            string = app:sub(1, 1),
            drawing = true,
            font = 'Helvetica Neue:Bold:11.0',
            color = numColor,
          },
          label = { drawing = false },
          background = { drawing = false },
          padding_left = 2,
          padding_right = rightPad,
        })
      end
      table.insert(members, appItem.name)
    end

    -- click_script, not bracket:subscribe('mouse.clicked', ...): confirmed
    -- live that the Lua-callback subscribe path never fires for mouse
    -- events (a debug log write placed first in that callback never
    -- happened on an actual click) -- click_script is sketchybar's C
    -- core invoking an external script directly on click, bypassing
    -- SbarLua's event dispatch entirely, which is more likely to be the
    -- actually-supported mechanism for this event type.
    local switchCmd = string.format(
      'echo "$(date) click_script fired for workspace %d" >> /tmp/scrollspace-click-debug.log; '
      .. 'export PATH="/run/current-system/sw/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"; '
      .. 'hs -c "ScrollSpace.workspace.switchWorkspace(%d)" >> /tmp/scrollspace-click-debug.log 2>&1',
      workspace, workspace
    )
    local bracket = sbar.add('bracket', 'workspace_bracket.' .. workspace, members, {
      background = {
        drawing = true,
        color = pillColor,
        border_color = borderColor,
        border_width = 1,
        corner_radius = 12,
        height = 24,
      },
      click_script = switchCmd,
    })

    newPrevious[workspace] = #ws.apps
  end
  previous = newPrevious

  sbar.end_config()
end

control:subscribe('scrollspace_workspace_change', rebuild)
rebuild() -- draw the initial state immediately, don't wait for the first change

-- ~/.config/sketchybar/items/paperwm.lua
--
-- Renders one rounded "pill" (SketchyBar bracket) per macOS Space (on
-- the main screen) that has at least one real window: a space number
-- plus the REAL icon of every app running in it, extracted via
-- app_icon.sh. Empty spaces get no pill.
--
-- Ported from the Paneru-based bash version (see git history) onto
-- PaperWM + SbarLua: hammerspoon/paperwm-sketchybar.lua writes
-- STATE_FILE and triggers paperwm_workspace_change on every space/
-- window change (plus its own 5s poll safety net) -- same role
-- scripts/paneru-subscribe played before.
--
-- SbarLua has no "move" primitive (unlike the bash CLI's --move) and no
-- way to edit an existing bracket's membership, so rather than diffing
-- against previous state, every rebuild removes everything it created
-- last time and re-adds everything fresh, in order -- creation order is
-- display order, which sidesteps needing "move" at all. Wrapped in
-- begin_config/end_config so a rebuild is one atomic message to
-- sketchybar, same reason the bash version batched everything into a
-- single `sketchybar` invocation: switching spaces should never show an
-- empty or half-built bar.

local CONFIG_DIR = os.getenv('HOME') .. '/.config/sketchybar'
local ICON_SCRIPT = CONFIG_DIR .. '/plugins/app_icon.sh'
local STATE_FILE = '/tmp/paperwm-state.txt'

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

sbar.add('event', 'paperwm_workspace_change')

local control = sbar.add('item', 'paperwm_control', { drawing = false })

-- number -> app count, from the last rebuild -- exactly what's needed
-- to know which item names to remove before rebuilding fresh
local previous = {}

local function rebuild()
  local f = io.open(STATE_FILE, 'r')
  if not f then
    return
  end

  local wanted = {}
  local order = {}
  for line in f:lines() do
    local number, id, active, apps = line:match('^(%d+) (%d+) (%d) (.*)$')
    if number then
      local appList = {}
      for app in (apps .. '|'):gmatch('([^|]*)|') do
        if app ~= '' then
          table.insert(appList, app)
        end
      end
      number = tonumber(number)
      wanted[number] = { id = tonumber(id), active = (active == '1'), apps = appList }
      table.insert(order, number)
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

  for number, appCount in pairs(previous) do
    sbar.remove('space_bracket.' .. number)
    sbar.remove('space.' .. number)
    sbar.remove('space.' .. number .. '.gap')
    for i = 1, appCount do
      sbar.remove('space.' .. number .. '.app' .. i)
    end
  end

  local newPrevious = {}
  local firstPill = true
  for _, number in ipairs(order) do
    local ws = wanted[number]
    local focused = ws.active
    local numColor = focused and F_NUM or U_NUM
    local pillColor = focused and F_PILL or U_PILL
    local borderColor = focused and F_BORDER or U_BORDER

    -- Invisible spacer between consecutive pills (not part of any bracket)
    if not firstPill then
      sbar.add('item', 'space.' .. number .. '.gap', {
        position = 'center',
        width = 8,
        icon = { drawing = false },
        label = { drawing = false },
        background = { drawing = false },
      })
    end
    firstPill = false

    local numberItem = sbar.add('item', 'space.' .. number, {
      position = 'center',
      icon = {
        string = tostring(number),
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

      -- Unfocused spaces get the 35%-opacity variant of each icon
      if iconPng and iconPng ~= '' and not focused then
        local dim = iconPng:gsub('%.png$', '_dim.png')
        if fileExists(dim) then
          iconPng = dim
        end
      end

      local itemName = 'space.' .. number .. '.app' .. i
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

    local spaceId = ws.id
    local bracket = sbar.add('bracket', 'space_bracket.' .. number, members, {
      background = {
        drawing = true,
        color = pillColor,
        border_color = borderColor,
        border_width = 1,
        corner_radius = 12,
        height = 24,
      },
    })
    bracket:subscribe('mouse.clicked', function()
      sbar.exec("hs -c 'hs.spaces.gotoSpace(" .. spaceId .. ")'")
    end)

    newPrevious[number] = #ws.apps
  end
  previous = newPrevious

  sbar.end_config()
end

control:subscribe('paperwm_workspace_change', rebuild)
rebuild() -- draw the initial state immediately, don't wait for the first change

function Get_local_plugin_path(plugin_name)
  return vim.fs.joinpath(vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'custom_plugins'), plugin_name)
end

require('config')
require('config.lazy')

vim.cmd.colorscheme('dayfox')
vim.fn.timer_start(300000, function()
  local hour = tonumber(os.date('%H'))
  local current = vim.g.colors_name

  if hour >= 7 and hour < 19 then
    if current ~= 'dayfox' then
      vim.cmd.colorscheme('dayfox')
    end
  else
    if current ~= 'carbonfox' then
      vim.cmd.colorscheme('carbonfox')
    end
  end
end, { ['repeat'] = -1 })

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

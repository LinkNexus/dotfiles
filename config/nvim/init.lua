function Get_local_plugin_path(plugin_name)
  return vim.fs.joinpath(vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'custom_plugins'), plugin_name)
end

require('config')
require('config.lazy')

vim.cmd.colorscheme('carbonfox')

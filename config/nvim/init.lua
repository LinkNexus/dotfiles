-- Helper function to get custom plugin path
function Get_local_plugin_path(plugin_name)
  return vim.fs.joinpath(vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'custom_plugins'), plugin_name)
end

-- Load core configuration (options, keymaps, autocmds)
require('config')

-- Load lazy.nvim plugin manager and plugins
require('config.lazy')

-- Colorscheme setup
vim.cmd.colorscheme('gruvbox-material')

-- local nightfox_themes = {
-- 	nightfox = true,
-- 	dayfox = true,
-- 	dawnfox = true,
-- 	duskfox = true,
-- 	nordfox = true,
-- 	terafox = true,
-- 	carbonfox = true,
-- }
--
-- if nightfox_themes[vim.g.colors_name] then
-- 	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "LspInlayHint", link = false })
-- 	if ok then
-- 		hl.italic = true
-- 		vim.api.nvim_set_hl(0, "LspInlayHint", hl)
-- 	end
-- end
--

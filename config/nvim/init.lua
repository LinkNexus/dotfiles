function Get_local_plugin_path(plugin_name)
    return vim.fs.joinpath(vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "custom_plugins"), plugin_name)
end

require("config.options")
require("config.lazy")

local nightfox_themes = {
    nightfox = true,
    dayfox = true,
    dawnfox = true,
    duskfox = true,
    nordfox = true,
    terafox = true,
    carbonfox = true,
}

local function apply_nightfox_inlay_hint_italics()
    if not nightfox_themes[vim.g.colors_name] then
        return
    end

    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "LspInlayHint", link = false })
    if not ok then
        return
    end

    hl.italic = true
    vim.api.nvim_set_hl(0, "LspInlayHint", hl)
end

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = { "nightfox", "dayfox", "dawnfox", "duskfox", "nordfox", "terafox", "carbonfox" },
    callback = apply_nightfox_inlay_hint_italics,
})

vim.cmd.colorscheme("dayfox")
apply_nightfox_inlay_hint_italics()

-- Global statusline (one line at the bottom for all windows)
vim.opt.laststatus = 3

-- Hide the default -- NORMAL -- / -- INSERT -- messages
vim.opt.showmode = false

-- Set command height to 0 to put lualine at the absolute bottom
-- Note: Messages will now appear over lualine or require a keypress to clear
vim.opt.cmdheight = 0

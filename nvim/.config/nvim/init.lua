-- require("vim._core.ui2").enable({})

require("utils.theme")
require("core")
require("core.lazy")

if GET_SYSTEM_THEME() == "dark" then
    vim.cmd.colorscheme("carbonfox")
    vim.o.background = "dark"
else
    vim.cmd.colorscheme("dayfox")
    vim.o.background = "light"
end

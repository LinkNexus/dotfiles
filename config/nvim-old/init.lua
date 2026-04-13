-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

require("mason").setup({
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",
  },
  ensure_installed = {
    "lua-language-server",
    "xmlformatter",
    "csharpier",
    "stylua",
    "html-lsp",
    "css-lsp",
    "typescript-language-server",
    "json-lsp",
    "roslyn",
    "netcoredbg",
    "clangd",
  },
})

vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]])
vim.cmd.colorscheme("material-deep-ocean")

require("lazyvim.util").root.get = vim.loop.cwd

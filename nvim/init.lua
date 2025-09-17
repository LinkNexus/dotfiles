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
    "prettier",
    "stylua",
    "bicep-lsp",
    "html-lsp",
    "css-lsp",
    "eslint-lsp",
    "typescript-language-server",
    "json-lsp",
    "rust-analyzer",
    "roslyn",
    "rzls",
    "netcoredbg",
  },
})

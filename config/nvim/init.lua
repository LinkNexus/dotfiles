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

-- Undo on Ctrl+_
vim.keymap.set("n", "<C-_>", "u", { noremap = true })
vim.keymap.set("i", "<C-_>", "<C-o>u", { noremap = true })

-- Redo on Ctrl-?
vim.keymap.set("n", "<C-?>", "<C-r>", { noremap = true })
vim.keymap.set("i", "<C-?>", "<C-o><C-r>", { noremap = true })

require("noice").setup({
  notify = {
    enabled = false, -- don't override vim.notify
  },
  lsp = {
    hover = {
      enabled = false, -- don't override vim.lsp.buf.hover
    },
    signature = {
      enabled = false, -- don't override vim.lsp.buf.signature_help
    },
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
      ["vim.lsp.util.stylize_markdown"] = false,
    },
  },
})

require("lazyvim.util").root.get = vim.loop.cwd
vim.cmd.colorscheme("catppuccin")

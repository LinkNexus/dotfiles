return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "javascript", "typescript", "php", "c_sharp" },
      highlight = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>", -- Start selection with Enter
          node_incremental = "<CR>", -- Expand to the next node
          scope_incremental = "<S-CR>", -- Expand to the current scope
          node_decremental = "<BS>", -- Shrink selection with Backspace
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Jump forward to nearest text object
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
          },
        },
        lsp_interop = {
          enable = true,
          border = "none",
          floating_preview_opts = {},
          peek_definition_code = {
            ["<leader>df"] = "@function.outer",
            ["<leader>dF"] = "@class.outer",
          },
        },
      },
    })
  end,
}

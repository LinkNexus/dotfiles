return {
  -- Better movement with vim-exchange
  {
    "tommcdo/vim-exchange",
    event = "VeryLazy",
  },

  -- Enhanced text objects and movement
  {
    "nvim-mini/mini.move",
    event = "VeryLazy",
    config = function()
      require("mini.move").setup({
        mappings = {
          left = "<C-S-h>",
          right = "<C-S-l>",
          down = "<C-S-j>",
          up = "<C-S-k>",

          line_left = "<C-S-h>",
          line_right = "<C-S-l>",
          line_down = "<C-S-j>",
          line_up = "<C-S-k>",
        },
      })
    end,
  },

  -- Visual multi-select and movement
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
  },
}

return {
  -- Better movement with vim-exchange
  {
    "tommcdo/vim-exchange",
    event = "VeryLazy",
  },

  -- Enhanced text objects and movement
  {
    "echasnovski/mini.move",
    event = "VeryLazy",
    config = function()
      require("mini.move").setup()
    end,
  },

  -- Visual multi-select and movement
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
  },
}

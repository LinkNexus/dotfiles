return {
  dir = "~/Labs/projects/nvim_plugins/makefile-runner.nvim", -- or wherever you place it
  dependencies = {
    "voldikss/vim-floaterm",
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("makefile-runner").setup({
      picker = "fzf",
      keymap = "<leader>m", -- Optional: set a keymap
    })
  end,
}

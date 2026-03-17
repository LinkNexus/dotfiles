local config_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "custom_plugins")

return {
  {
    dir = vim.fs.joinpath(config_dir, "makefile_runner.nvim"),
    dependencies = {
      "voldikss/vim-floaterm",
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("makefile-runner").setup({
        picker = "fzf",
        keymap = "<leader>m",
      })
    end,
  },
  {
    dir = vim.fs.joinpath(config_dir, "cpp_header_sync.nvim"),
    config = function()
      require("cpp_header_sync").setup()
    end,
  },
}

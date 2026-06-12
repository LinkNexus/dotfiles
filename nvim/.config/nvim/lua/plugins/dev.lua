return {
  {
    "DrKJeff16/wezterm-types",
    version = false,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "wezterm-types",      mods = { "wezterm" } },
      },
      enabled = function(root_dir)
        return (not vim.uv.fs_stat(root_dir .. "/.luarc.json"))
            and (vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled)
      end,
    },
  },
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      ---@module "ibl"
      ---@type ibl.config
      local opts = {
        scope = {
          enabled = true
        },
        whitespace = {
          remove_blankline_trail = true
        }
      }

      require("ibl").setup(opts)
    end
  },
  {
    'stevearc/overseer.nvim',
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {},
  }
}

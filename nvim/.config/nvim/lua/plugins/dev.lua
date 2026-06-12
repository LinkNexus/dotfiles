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
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
    },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({})
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    version = "^1948B6-8B13.0.0",
    opts = {
      log_level = "DEBUG",
      interactions = {
        chat = {
          adapter = "copilot_acp"
        },
        cli = {
          agent = "copilot",
          agents = {
            copilot = {
              cmd = "copilot",
              args = {},
              description = "Code Companion CLI using Copilot",
              provider = "terminal"
            }
          }
        }
      }
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
    end,
  },
}

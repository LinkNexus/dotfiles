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
        indent = {
          char = require("ibl.utils").get_listchars(0).space_char,
        },
        scope = {
          enabled = true,
          char = "▎",
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
  },
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
    },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        nes = {
          enabled = false
        }
      })
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
  {
    "folke/sidekick.nvim",
    opts = {
      -- add any options here
      cli = {
        mux = {
          backend = "zellij",
          enabled = true,
        },
      },
    },
    keys = {
      {
        "<tab>",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>" -- fallback to normal tab
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
    }
  },
  {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      "sindrets/diffview.nvim", -- optional
      "m00qek/baleia.nvim",     -- optional
      "ibhagwan/fzf-lua",       -- optional
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gU", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
    }
  }
}

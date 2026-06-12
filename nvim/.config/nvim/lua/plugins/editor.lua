return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore session for current dir",
      },
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "Select session to restore",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Stop persistence for current session (session won't be saved on exit)",
      },
    },
  },
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        -- ...
        signs = {
          left = "",
          right = "",
          diag = "●",
          arrow = "    ",
          up_arrow = "    ",
          vertical = " │",
          vertical_end = " └",
        },
        blend = {
          factor = 0.22,
        },
        -- ...
      })
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
    },
    opts = {
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
    },
  },
  {
    "tpope/vim-sleuth",
  },
  {
    "tpope/vim-surround"
  },
  ---@type LazySpec
  {
    "mikavilpas/yazi.nvim",
    version = "*", -- use the latest stable version
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      -- 👇 in this section, choose your own keymappings!
      {
        "<leader>ef",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        -- Open in the current working directory
        "<leader>ew",
        "<cmd>Yazi cwd<cr>",
        desc = "Open the file manager in nvim's working directory",
      },
      {
        "<leader>ee",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume the last yazi session",
      },
    },
    ---@type YaziConfig | {}
    opts = {
      -- if you want to open yazi instead of netrw, see below for more info
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
      highlight_hovered_buffers_in_same_directory = false
    },
    -- 👇 if you use `open_for_directories=true`, this is recommended
    init = function()
      -- mark netrw as loaded so it's not loaded at all.
      --
      -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      vim.g.loaded_netrwPlugin = 1
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { "markdown", "codecompanion" },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      completions = {
        lsp = {
          enable = true,
        }
      }
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      filetypes = {
        codecompanion = {
          prompt_for_file_name = false,
          template = "[Image]($FILE_PATH)",
          use_absolute_path = true,
        }
      }
    },
    keys = {
      -- suggested keymap
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  }
}

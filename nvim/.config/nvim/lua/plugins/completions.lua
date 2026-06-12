return {
  {
    "saghen/blink.cmp",
    version = "2.*",
    dependencies = {
      'saghen/blink.lib',
      "folke/lazydev.nvim",
      'rafamadriz/friendly-snippets',
      "fang2hou/blink-copilot"
    },
    build = function()
      -- build the fuzzy matcher, optionally add a timeout to `pwait(timeout_ms)`
      -- you can use `gb` in `:Lazy` to rebuild the plugin as needed
      require('blink.cmp').build():pwait()
    end,
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
      },
      signature = { enabled = true },
      cmdline = {
        enabled = false,
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = {
          auto_show = true,
        },
        list = {
          -- Maximum number of items to display
          max_items = 100,

          selection = {
            -- When `true`, will automatically select the first item in the completion list
            preselect = true,
            -- When `true`, inserts the completion item automatically when selecting it
            -- You may want to bind a key to the `cancel` command (default <C-e>) when using this option,
            -- which will both undo the selection and hide the completion menu
            auto_insert = false,
          },
          cycle = {
            from_bottom = true,
            from_top = true,
          },
        },
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev", "copilot" },
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- make lazydev completions top priority (see `:h blink.cmp`)
          },
        },
      },
    },
    opts_extend = { "sources.default" }
  },
}

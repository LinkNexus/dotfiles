return {
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      -- Available themes: "wave", "dragon", "lotus"
      theme = "wave",
      commentStyle = { italic = true },
      functionStyle = { bold = true, italic = true },
      keywordStyle = { underline = true },
      statementStyle = { italic = true },
      typeStyle = { bold = true },

      dimInactive = false,
      globalStatus = true,

      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      overrides = function()
        return {
          NormalFloat = { bg = "none" },
        }
      end,
    },
  },

  {
    "marko-cerovac/material.nvim",
    lazy = false,
    opts = {
      theme = "deep-ocean", -- darker, lighter, oceanic, palenight, deep ocean
      -- disable = {
      --   background = true,
      -- },
      contrast = {
        sidebars = true,
        floating_windows = false,
        line_numbers = true,
        cursor_line = true,
        non_current_windows = true,
        popup_menu = false,
      },
      styles = {
        comments = { italic = true },
        strings = { italic = true },
        keywords = { bold = true, italic = true },
        functions = { bold = true, italic = true },
        -- variables = { bold = true },
        -- operators = {},
        types = { bold = true },
        -- numbers = { bold = true },
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
      -- transparent = true,
      styles = {
        comments = { italic = true },
        strings = { italic = true },
        keywords = { bold = true, italic = true },
        functions = { bold = true, italic = true },
        -- variables = { bold = true },
        -- operators = {},
        types = { bold = true },
        -- numbers = { bold = true },
        -- sidebar = "transparent",
        -- floats = "transparent",
      },
    },
  },
}

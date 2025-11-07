return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false, -- load immediately, not lazily
    priority = 1000, -- load before other plugins
    opts = {
      -- Available themes: "wave", "dragon", "lotus"
      theme = "lotus",
      commentStyle = { italic = true },
      functionStyle = { bold = true, italic = true },
      keywordStyle = {},
      statementStyle = { italic = true },
      typeStyle = { bold = true },

      -- Optional customization
      transparent = true, -- set to true for transparent background
      dimInactive = false, -- dim inactive windows
      globalStatus = true, -- use global statusline

      -- Color overrides
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none", -- remove gutter background
            },
          },
        },
      },

      -- Plugin integrations
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- Custom overrides can go here
          NormalFloat = { bg = "none" },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },
  {
    "marko-cerovac/material.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      theme = "palenight", -- darker, lighter, oceanic, palenight, deep ocean
      disable = {
        background = true,
      },
      contrast = {
        sidebars = true,
        floating_windows = true,
        line_numbers = true,
        cursor_line = true,
        non_current_windows = true,
        popup_menu = true,
      },
      styles = {
        comments = { italic = true },
        -- strings = { italic = true },
        -- keywords = { underline = true },
        functions = { bold = true, italic = true },
        variables = { bold = true },
        operators = {},
        types = { bold = true },
        numbers = { bold = true },
      },
    },
    config = function(_, opts)
      require("material").setup(opts)
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      -- Optionally configure and load the colorscheme
      -- directly inside the plugin declaration.
      vim.g.gruvbox_material_enable_italic = true
      -- vim.cmd.colorscheme("gruvbox-material")
    end,
  },
}

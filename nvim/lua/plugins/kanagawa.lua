return {
  {
    "rebelot/kanagawa.nvim",
    lazy = true, -- load immediately, not lazily
    priority = 1000, -- load before other plugins
    opts = {
      -- Available themes: "wave", "dragon", "lotus"
      theme = "lotus",
      commentStyle = { italic = true },
      functionStyle = { italic = true },
      keywordStyle = {},
      statementStyle = {},
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
}

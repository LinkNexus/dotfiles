return {
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    config = function()
      -- vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "original"
      -- vim.g.gruvbox_material_transparent_background = true
      vim.g.gruvbox_material_diagnostic_text_highlight = "1"
      vim.g.gruvbox_material_diagnostic_line_highlight = "1"
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
    opts = {
      options = {
        transparent = true,
        styles = {
          -- comments = 'italic',
          constants = "bold",
          keywords = "bold",
          types = "bold",
          -- strings = 'italic',
          functions = "bold",
          -- conditionals = 'italic',
        },
      },
    },
  },
}

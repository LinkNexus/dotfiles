return {
  {
    'sainnhe/gruvbox-material',
    lazy = true,
    config = function()
      -- vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_background = 'hard'
      vim.g.gruvbox_material_foreground = 'original'
      -- vim.g.gruvbox_material_transparent_background = true
      vim.g.gruvbox_material_diagnostic_text_highlight = '1'
      vim.g.gruvbox_material_diagnostic_line_highlight = '1'
    end,
  },
  { 'catppuccin/nvim', name = 'catppuccin', lazy = true },
  {
    'rebelot/kanagawa.nvim',
    lazy = true,
    opts = {
      -- Available themes: "wave", "dragon", "lotus"
      compile = true,
      theme = 'wave',
      -- commentStyle = { italic = true },
      -- functionStyle = { italic = true, bold = true },
      -- keywordStyle = { italic = true },
      -- statementStyle = { italic = true },
      -- typeStyle = { bold = true, italic = true },

      dimInactive = false,
      globalStatus = true,

      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = 'none',
            },
          },
        },
      },
      overrides = function()
        return {
          NormalFloat = { bg = 'none' },
        }
      end,
    },
  },
  {
    'EdenEast/nightfox.nvim',
    lazy = true,
    opts = {
      options = {
        styles = {
          -- comments = 'italic',
          -- constants = 'bold',
          -- keywords = 'bold',
          -- types = 'bold',
          -- strings = 'italic',
          -- functions = 'bold',
          -- conditionals = 'italic',
        },
      },
    },
  },
}

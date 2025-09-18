return {
  {
    "marko-cerovac/material.nvim",
    lazy = false,
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
      vim.cmd.colorscheme("material")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "material",
    },
  },
}

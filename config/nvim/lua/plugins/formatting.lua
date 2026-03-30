return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.lua = { "stylua" }
      opts.formatters_by_ft.javascript = { "biome-check" }
      opts.formatters_by_ft.javascriptreact = { "biome-check" }
      opts.formatters_by_ft.typescript = { "biome-check" }
      opts.formatters_by_ft.typescriptreact = { "biome-check" }
      opts.formatters_by_ft.json = { "biome-check" }
      opts.formatters_by_ft.jsonc = { "biome-check" }

      opts.formatters = opts.formatters or {}
      opts.formatters.stylua = {
        prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
      }
    end,
  },
}

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts_extend = { "ensure_installed" },
    opts = {
      registries = { "github:crashdummyy/mason-registry", "github:mason-org/mason-registry" },
      ensure_installed = {
        "stylua",
        "shfmt",
        "lua-language-server",
        "xmlformatter",
        "csharpier",
        "html-lsp",
        "css-lsp",
        "vtsls",
        "biome",
        "json-lsp",
        "roslyn",
        "netcoredbg",
        "black",
        "clangd",
        "clang-format",
        "codelldb",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local ok, pkg = pcall(mr.get_package, tool)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },
}

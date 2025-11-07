local cmp = require("cmp")
cmp.setup({
  sources = cmp.config.sources({
    { name = "laravel" }, -- ✅ Laravel completion
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  }),
})

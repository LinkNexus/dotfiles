return {
  {
    "TheLeoP/powershell.nvim",
    ft = { "ps1" },
    config = function()
      local bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
      require("powershell").setup({
        bundle_path = bundle_path,
        shell = "pwsh",
      })
    end,
  },
}

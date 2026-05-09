return {
  {
    "TheLeoP/powershell.nvim",
    ft = { "ps1" },
    dependencies = {
      "mason-org/mason.nvim",
    },
    config = function()
      local bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
      
      -- Verify bundle path exists
      if vim.fn.isdirectory(bundle_path) == 0 then
        vim.notify("PowerShell Editor Services not found at: " .. bundle_path, vim.log.levels.WARN)
        return
      end
      
      require("powershell").setup({
        bundle_path = bundle_path,
        shell = "pwsh",
      })
    end,
  },
}

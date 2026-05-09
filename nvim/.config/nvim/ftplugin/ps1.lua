vim.keymap.set("n", "<leader>lt", function()
  require("powershell").toggle_term()
end, { buffer = true, desc = "Toggle PowerShell Extension Terminal" })

vim.keymap.set({ "n", "x" }, "<leader>le", function()
  require("powershell").eval()
end, { buffer = true, desc = "Eval in PowerShell Terminal" })

vim.keymap.set("n", "<leader>ld", function()
  require("powershell").toggle_debug_term()
end, { buffer = true, desc = "Toggle PowerShell Debug Terminal" })

-- PowerShell-specific configuration and keymaps

-- PowerShell keymaps for .ps1 files
vim.keymap.set("n", "<leader>lt", function() 
  require("powershell").toggle_term() 
end, { desc = "Toggle PowerShell Extension Terminal", buffer = true })

vim.keymap.set({ "n", "x" }, "<leader>le", function() 
  require("powershell").eval() 
end, { desc = "Eval PowerShell expression", buffer = true })

vim.keymap.set("n", "<leader>ld", function() 
  require("powershell").toggle_debug_term() 
end, { desc = "Toggle PowerShell Debug Terminal", buffer = true })

-- Additional PowerShell-specific options
vim.opt_local.commentstring = "# %s"
vim.opt_local.iskeyword:append("-")

-- Set up buffer-local abbreviations for common PowerShell patterns
vim.cmd([[
  iabbrev <buffer> pso [PSObject]
  iabbrev <buffer> str [String]
  iabbrev <buffer> int [Int]
  iabbrev <buffer> arr [Array]
  iabbrev <buffer> ht [Hashtable]
]])
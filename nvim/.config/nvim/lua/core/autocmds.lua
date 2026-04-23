vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

local powershell_augroup = vim.api.nvim_create_augroup("powershell-terminal", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = powershell_augroup,
	pattern = "powershell.nvim-term",
	callback = function(opts)
		-- Terminal-specific keymap for closing the terminal
		vim.keymap.set("n", "<leader>lt", function()
			require("powershell").toggle_term()
		end, { buffer = opts.data.buf, desc = "Close PowerShell Extension Terminal" })
		
		-- Additional terminal-specific settings
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = powershell_augroup,
	pattern = "powershell.nvim-debug_term",
	callback = function(opts)
		-- Terminal-specific keymap for closing the debug terminal
		vim.keymap.set("n", "<leader>ld", function()
			require("powershell").toggle_debug_term()
		end, { buffer = opts.data.buf, desc = "Close PowerShell Debug Terminal" })
		
		-- Additional terminal-specific settings
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

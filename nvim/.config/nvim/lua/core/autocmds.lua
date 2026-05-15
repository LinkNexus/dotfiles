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
			require("core.powershell").toggle_term()
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
			require("core.powershell").toggle_debug_term()
		end, { buffer = opts.data.buf, desc = "Close PowerShell Debug Terminal" })
		
		-- Additional terminal-specific settings
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = powershell_augroup,
	pattern = { "ps1", "psm1", "psd1" },
	callback = function(opts)
		require("core.powershell").initialize_or_attach(opts.buf)
		vim.opt_local.number = true
		vim.opt_local.relativenumber = true
		vim.opt_local.signcolumn = "yes"
		vim.keymap.set("n", "<leader>lt", function()
			require("core.powershell").toggle_term()
		end, { buffer = opts.buf, desc = "PowerShell Extension Terminal" })
		vim.keymap.set({ "n", "x" }, "<leader>le", function()
			require("core.powershell").eval()
		end, { buffer = opts.buf, desc = "PowerShell Eval" })
		vim.keymap.set("n", "<leader>ld", function()
			require("core.powershell").toggle_debug_term()
		end, { buffer = opts.buf, desc = "PowerShell Debug Terminal" })
	end,
})

-- Auto commands

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- PowerShell.nvim terminal-specific keymaps (only for terminal buffers)
local powershell_augroup = vim.api.nvim_create_augroup("powershell-terminal", { clear = true })

-- Extension Terminal: Add keymap to close/toggle terminal from within the terminal
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

-- Debug Terminal: Add keymap to close/toggle debug terminal from within the terminal
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

-- Nightfox colorscheme: apply italic style to inlay hints
local nightfox_themes = {
	nightfox = true,
	dayfox = true,
	dawnfox = true,
	duskfox = true,
	nordfox = true,
	terafox = true,
	carbonfox = true,
}

local function apply_nightfox_inlay_hint_italics()
	if not nightfox_themes[vim.g.colors_name] then
		return
	end

	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "LspInlayHint", link = false })
	if not ok then
		return
	end

	hl.italic = true
	vim.api.nvim_set_hl(0, "LspInlayHint", hl)
end

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = { "nightfox", "dayfox", "dawnfox", "duskfox", "nordfox", "terafox", "carbonfox" },
	callback = apply_nightfox_inlay_hint_italics,
})

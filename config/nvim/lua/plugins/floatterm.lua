return {
  "voldikss/vim-floaterm",
  event = "VeryLazy",
  config = function()
    vim.keymap.set("n", "<leader>tt", "<cmd>FloatermToggle<cr>", { desc = "Toggle Floaterm" })
    vim.keymap.set("n", "<leader>tn", "<cmd>FloatermNew<cr>", { desc = "New Floaterm" })
    vim.keymap.set("n", "<leader>tk", "<cmd>FloatermKill<cr>", { desc = "Kill Current Floaterm" })
    vim.keymap.set("n", "<leader>tp", "<cmd>FloatermPrev<cr>", { desc = "Previous Floaterm" })
    vim.keymap.set("n", "<leader>tj", "<cmd>FloatermNext<cr>", { desc = "Next Floaterm" })
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit Terminal Mode" })

    vim.keymap.set("n", "<leader>tc", "<cmd>FloatermNew --name=copilot copilot<cr>", { desc = "Open Copilot CLI" })
    vim.keymap.set("n", "<leader>td", "<cmd>FloatermNew --name=lazydocker lazydocker<cr>", { desc = "Open Lazydocker" })

    -- In terminal mode, <Esc> goes to terminal program, <C-Space> exits terminal mode
    vim.keymap.set("t", "<Esc>", "<Esc>", { noremap = true })

    vim.g.floaterm_autoinsert = 0
    vim.g.floaterm_width = 0.85
    vim.g.floaterm_height = 0.85

    -- Send current line
    vim.keymap.set("n", "<leader>tl", function()
      vim.cmd("FloatermSend " .. vim.fn.getline("."))
    end, { desc = "Send Current Line to Floaterm" })

    -- Send selection
    vim.keymap.set("v", "<leader>tv", function()
      local _, ls, cs = unpack(vim.fn.getpos("'<"))
      local _, le, ce = unpack(vim.fn.getpos("'>"))
      local lines = vim.fn.getline(ls, le)
      lines[#lines] = string.sub(lines[#lines], 1, ce)
      lines[1] = string.sub(lines[1], cs)
      local text = table.concat(lines, "\n")
      vim.cmd("FloatermSend " .. text)
    end, { desc = "Send Visual Selection to Floaterm" })
  end,
}

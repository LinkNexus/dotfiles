return {
  {
    "voldikss/vim-floaterm",
    event = "VeryLazy",
    config = function()
      vim.keymap.set("n", "<leader>tt", "<cmd>FloatermToggle<cr>", { desc = "Toggle Floaterm" })
      vim.keymap.set("n", "<leader>tn", "<cmd>FloatermNew<cr>", { desc = "New Floaterm" })
      vim.keymap.set("n", "<leader>tk", "<cmd>FloatermKill<cr>", { desc = "Kill Current Floaterm" })
      vim.keymap.set("n", "<leader>tp", "<cmd>FloatermPrev<cr>", { desc = "Previous Floaterm" })
      vim.keymap.set("n", "<leader>tj", "<cmd>FloatermNext<cr>", { desc = "Next Floaterm" })

      vim.keymap.set("n", "<leader>to", "<cmd>FloatermNew --name=opencode opencode<cr>", { desc = "Open Opencode CLI" })

      vim.keymap.set("t", "<Esc>", "<Esc>", { noremap = true })

      vim.g.floaterm_autoinsert = 0
      vim.g.floaterm_width = 0.75
      vim.g.floaterm_height = 0.75

      vim.keymap.set("n", "<leader>tl", function()
        vim.cmd("FloatermSend " .. vim.fn.getline("."))
      end, { desc = "Send Current Line to Floaterm" })

      vim.keymap.set("v", "<leader>tv", function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

        vim.schedule(function()
          local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
          if #lines > 0 then
            local cmd = table.concat(lines, " "):gsub("^%s*(.-)%s*$", "%1")
            vim.cmd("FloatermNew --autoclose=0 " .. cmd)
          end
        end)
      end, { desc = "Run Selection in New Floaterm" })

      vim.keymap.set("n", "<leader>tl", function()
        local line = vim.fn.getline("."):gsub("^%s*(.-)%s*$", "%1")
        if line ~= "" then
          vim.cmd("FloatermNew --autoclose=0 " .. line)
        end
      end, { desc = "Run Line in New Floaterm" })
    end,
  },
}

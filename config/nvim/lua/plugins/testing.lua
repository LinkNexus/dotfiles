return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "Issafalcon/neotest-dotnet",
    "nsidorenco/neotest-vstest",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-vstest"),
      },
    })

    local map = vim.keymap.set

    map("n", "<leader>Tt", "<Cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>", {
      noremap = true,
      silent = true,
      desc = "run all tests in current file",
    })

    map("n", "<leader>Tr", "<Cmd>lua require('neotest').run.run()<CR>", {
      noremap = true,
      silent = true,
      desc = "run nearest test",
    })

    map("n", "<leader>Ts", "<Cmd>lua require('neotest').summary.toggle()<CR>", {
      noremap = true,
      silent = true,
      desc = "toggle test summary",
    })

    map("n", "<leader>To", "<Cmd>lua require('neotest').output.open({ enter = true })<CR>", {
      noremap = true,
      silent = true,
      desc = "open test output",
    })

    map("n", "<leader>TD", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>", {
      noremap = true,
      silent = true,
      desc = "debug nearest test",
    })

    map("n", "<leader>Tl", "<Cmd>lua require('neotest').run.run_last()<CR>", {
      noremap = true,
      silent = true,
      desc = "run last test",
    })
  end,
}

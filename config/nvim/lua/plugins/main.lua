return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "material-deep-ocean",
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    event = "VeryLazy",
    config = function()
      -- require("lazydev").setup({
      --   library = { "nvim-dap-ui" },
      -- })
      local dap, dapui = require("dap"), require("dapui")

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end

      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }
      map(
        "n",
        "<F5>",
        "<Cmd>lua require'dap'.continue()<CR>",
        { noremap = true, silent = true, desc = "Dap: Continue" }
      )
      map(
        "n",
        "<F6>",
        "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>",
        { noremap = true, silent = true, desc = "Neotest: Run with DAP" }
      )
      map(
        "n",
        "<F9>",
        "<Cmd>lua require'dap'.toggle_breakpoint()<CR>",
        { noremap = true, silent = true, desc = "Dap: Toggle Breakpoint" }
      )
      map(
        "n",
        "<F10>",
        "<Cmd>lua require'dap'.step_over()<CR>",
        { noremap = true, silent = true, desc = "Dap: Step Over" }
      )
      map(
        "n",
        "<F11>",
        "<Cmd>lua require'dap'.step_into()<CR>",
        { noremap = true, silent = true, desc = "Dap: Step Into" }
      )
      map(
        "n",
        "<F8>",
        "<Cmd>lua require'dap'.step_out()<CR>",
        { noremap = true, silent = true, desc = "Dap: Step Out" }
      )
      map(
        "n",
        "<F12>",
        "<Cmd>lua require'dap'.step_out()<CR>",
        { noremap = true, silent = true, desc = "Dap: Step Out" }
      )
      map(
        "n",
        "<leader>dr",
        "<Cmd>lua require'dap'.repl.open()<CR>",
        { noremap = true, silent = true, desc = "Dap: Open REPL" }
      )
      map(
        "n",
        "<leader>dl",
        "<Cmd>lua require'dap'.run_last()<CR>",
        { noremap = true, silent = true, desc = "Dap: Run Last" }
      )
      map(
        "n",
        "<leader>du",
        "<Cmd>lua require('dapui').toggle()<CR>",
        { noremap = true, silent = true, desc = "Dap UI: Toggle" }
      )
      map({ "n", "v" }, "dw", function()
        require("dapui").eval(nil, { enter = true })
      end, { noremap = true, silent = true, desc = "Dap UI: Evaluate" })

      vim.fn.sign_define("DapBreakpoint", {
        text = "⚪",
        texthl = "DapBreakpointSymbol",
        linehl = "DapBreakpoint",
        numhl = "DapBreakpoint",
      })

      vim.fn.sign_define("DapStopped", {
        text = "🔴",
        texthl = "yellow",
        linehl = "DapBreakpoint",
        numhl = "DapBreakpoint",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = "⭕",
        texthl = "DapStoppedSymbol",
        linehl = "DapBreakpoint",
        numhl = "DapBreakpoint",
      })

      -- dapui.setup()
      dapui.setup({
        expand_lines = true,
        controls = { enabled = false },
        floating = { border = "rounded" },
        render = {
          max_type_length = 60,
          max_value_lines = 200,
        },
        layouts = {
          {
            -- bottom: scopes + repl side by side
            elements = {
              { id = "scopes", size = 0.6 },
              { id = "repl", size = 0.4 },
            },
            size = 15,
            position = "bottom",
          },
          {
            -- right side: console for stdout
            elements = {
              { id = "console", size = 1.0 },
            },
            size = 40,
            position = "right",
          },
        },
      })
    end,
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        -- ...
        signs = {
          left = "",
          right = "",
          diag = "●",
          arrow = "    ",
          up_arrow = "    ",
          vertical = " │",
          vertical_end = " └",
        },
        blend = {
          factor = 0.22,
        },
        -- ...
      })
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      },
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore last session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Stop session saving",
      },
    },
  },
  {
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
  },
  {
    "mistweaverco/kulala.nvim",
    keys = {
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
    },
    ft = { "http", "rest" },
    opts = {
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
    },
  },
  {
    "miversen33/netman.nvim",
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "md" },
  },
}

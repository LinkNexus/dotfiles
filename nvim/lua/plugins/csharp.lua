return {
  {
    "seblyng/roslyn.nvim",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    ft = { "cs", "razor" },
    opts = {
      -- your configuration comes here; leave empty for default settings
    },

    -- ADD THIS:

    dependencies = {
      {
        -- By loading as a dependencies, we ensure that we are available to set
        -- the handlers for Roslyn.
        "tris203/rzls.nvim",
        config = true,
      },
    },
    lazy = false,
    config = function()
      -- Use one of the methods in the Integration section to compose the command.
      local mason_registry = require("mason-registry")

      local rzls_path = vim.fn.expand("$MASON/packages/rzls/libexec")
      local cmd = {
        "roslyn",
        "--stdio",
        "--logLevel=Information",
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
        "--razorSourceGenerator=" .. vim.fs.joinpath(rzls_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
        "--razorDesignTimePath=" .. vim.fs.joinpath(rzls_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
        "--extension",
        vim.fs.joinpath(rzls_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
      }

      vim.lsp.config("roslyn", {
        cmd = cmd,
        handlers = require("rzls.roslyn_handlers"),
        settings = {
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,

            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      })
      vim.lsp.enable("roslyn")
    end,
    init = function()
      -- We add the Razor file types before the plugin loads.
      vim.filetype.add({
        extension = {
          razor = "razor",
          cshtml = "razor",
        },
      })
    end,
  },
  {
    "ramboe/ramboe-dotnet-utils",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    config = function()
      require("dap-scope-walker").setup()
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local dap = require("dap")

      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg"

      local netcoredbg_adapter = {
        type = "executable",
        command = mason_path,
        args = { "--interpreter=vscode" },
      }

      dap.adapters.netcoredbg = netcoredbg_adapter -- needed for normal debugging
      dap.adapters.coreclr = netcoredbg_adapter -- needed for unit test debugging

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "launch - netcoredbg",
          request = "launch",
          program = function()
            return require("dap-dll-autopicker").build_dll_path()
          end,

          -- justMyCode = false,
          -- stopAtEntry = false,
          -- -- program = function()
          -- --   -- todo: request input from ui
          -- --   return "/path/to/your.dll"
          -- -- end,
          -- env = {
          --   ASPNETCORE_ENVIRONMENT = function()
          --     -- todo: request input from ui
          --     return "Development"
          --   end,
          --   ASPNETCORE_URLS = function()
          --     -- todo: request input from ui
          --     return "http://localhost:5050"
          --   end,
          -- },
          -- cwd = function()
          --   -- todo: request input from ui
          --   return vim.fn.getcwd()
          -- end,
        },
      }

      local map = vim.keymap.set

      local opts = { noremap = true, silent = true }

      map("n", "<F5>", "<Cmd>lua require'dap'.continue()<CR>", opts)
      map("n", "<F6>", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>", opts)
      map("n", "<F9>", "<Cmd>lua require'dap'.toggle_breakpoint()<CR>", opts)
      map("n", "<F10>", "<Cmd>lua require'dap'.step_over()<CR>", opts)
      map("n", "<F11>", "<Cmd>lua require'dap'.step_into()<CR>", opts)
      map("n", "<F8>", "<Cmd>lua require'dap'.step_out()<CR>", opts)
      -- map("n", "<F12>", "<Cmd>lua require'dap'.step_out()<CR>", opts)
      map("n", "<leader>dr", "<Cmd>lua require'dap'.repl.open()<CR>", opts)
      map("n", "<leader>dl", "<Cmd>lua require'dap'.run_last()<CR>", opts)
      map(
        "n",
        "<leader>dt",
        "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>",
        { noremap = true, silent = true, desc = "debug nearest test" }
      )
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    config = function()
      local dapui = require("dapui")
      local dap = require("dap")

      --- open ui immediately when debugging starts
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- https://emojipedia.org/en/stickers/search?q=circle
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

      -- more minimal ui
      dapui.setup({
        expand_lines = true,
        controls = { enabled = false }, -- no extra play/step buttons
        floating = { border = "rounded" },
        -- Set dapui window
        render = {
          max_type_length = 60,
          max_value_lines = 200,
        },
        -- Only one layout: just the "scopes" (variables) list at the bottom
        layouts = {
          {
            elements = {
              { id = "scopes", size = 1.0 }, -- 100% of this panel is scopes
            },
            size = 15, -- height in lines (adjust to taste)
            position = "bottom", -- "left", "right", "top", "bottom"
          },
        },
      })
    end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "Issafalcon/neotest-dotnet",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-dotnet"),
        },
      })
    end,
  },
  {
    "Issafalcon/neotest-dotnet",
    lazy = false,
    dependencies = {
      "nvim-neotest/neotest",
    },
  },
}

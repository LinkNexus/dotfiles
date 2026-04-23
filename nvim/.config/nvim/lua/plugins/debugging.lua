local function get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  local args_str = type(args) == "table" and table.concat(args, " ") or args

  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str))
    return require("dap.utils").splitstr(new_args)
  end

  return config
end

local function get_mason_adapter(executable_name)
  local ok_registry, mr = pcall(require, "mason-registry")

  if ok_registry and mr.is_installed(executable_name) then
    local mason_shim = vim.fn.stdpath("data") .. "/mason/bin/" .. executable_name
    if vim.fn.executable(mason_shim) == 1 then
      return mason_shim
    end
  end

  return executable_name
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
      "ramboe/ramboe-dotnet-utils",
    },
    keys = {
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Run/Continue",
      },
      {
        "<leader>da",
        function()
          require("dap").continue({ before = get_args })
        end,
        desc = "Run with Args",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>dg",
        function()
          require("dap").goto_()
        end,
        desc = "Go to Line (No Execute)",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>dj",
        function()
          require("dap").down()
        end,
        desc = "Down",
      },
      {
        "<leader>dk",
        function()
          require("dap").up()
        end,
        desc = "Up",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dP",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle({})
        end,
        desc = "Dap UI",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "Eval",
        mode = { "n", "x" },
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Widgets",
      },
    },

    config = function()
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define(
        "DapStopped",
        { text = "▶", texthl = "DiagnosticInfo", linehl = "Visual" }
      )

      local ok_vscode, vscode = pcall(require, "dap.ext.vscode")
      if ok_vscode then
        vscode.json_decode = function(str)
          local ok_json, json = pcall(require, "plenary.json")
          if ok_json then
            return vim.json.decode(json.json_strip_comments(str))
          end
          return vim.json.decode(str)
        end
      end

      local dap = require("dap")

      -- C & C++ config
      dap.adapters.codelldb = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = get_mason_adapter("codelldb"),
          args = { "--port", "${port}" },
        },
      }

      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = {
          {
            name = "Launch file",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
          },
          {
            name = "Launch file (with args)",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = function()
              local input = vim.fn.input("Program arguments: ")
              return require("dap.utils").splitstr(input)
            end,
          },
          {
            name = "Attach to process",
            type = "codelldb",
            request = "attach",
            pid = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }

        -- Dotnet / C# config
        local netcoredbg_adapter = {
          type = "executable",
          command = get_mason_adapter("netcoredbg"),
          args = { "--interpreter=vscode" },
        }

        dap.adapters.netcoredbg = netcoredbg_adapter
        dap.adapters.coreclr = netcoredbg_adapter

        local function resolve_dll_path()
          local ok_picker, picker = pcall(require, "dap-dll-autopicker")
          if ok_picker and type(picker.build_dll_path) == "function" then
            return picker.build_dll_path()
          end
          return vim.fn.input("Path to .dll: ", vim.fn.getcwd() .. "/", "file")
        end

        dap.configurations.cs = {
          {
            type = "coreclr",
            name = "launch - netcoredbg",
            request = "launch",
            program = resolve_dll_path,
            cwd = function()
              local dll = resolve_dll_path()
              return vim.fn.fnamemodify(dll, ":h:h:h:h")
            end,
            env = {
              ASPNETCORE_ENVIRONMENT = "Development",
              DOTNET_ENVIRONMENT = "Development",
            },
            justMyCode = true,
          },
        }

        pcall(function()
          require("dap-scope-walker").setup()
        end)
      end

      -- Dap Ui Setup
      local dapui = require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
      dapui.setup({})
    end,
  },
}

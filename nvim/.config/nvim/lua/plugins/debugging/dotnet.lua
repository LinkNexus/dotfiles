local M = {}
local dap = require("dap")
local debugging_utils = require("plugins.debugging.utils")

local function get_launch_settings(project_root)
  local path = project_root .. "/Properties/launchSettings.json"

  if vim.fn.filereadable(path) == 0 then
    return {}
  end

  local json = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))

  -- choose https profile if present, otherwise first profile
  local profile = json.profiles.https
      or json.profiles.http
      or vim.tbl_values(json.profiles)[1]

  return {
    urls = profile.applicationUrl,
    env = profile.environmentVariables or {},
  }
end

function M.setup()
  local netcoredbg_adapter = {
    type = "executable",
    command = debugging_utils.get_mason_adapter("netcoredbg"),
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

  local selected_dll;

  dap.configurations.cs = {
    {
      type = "coreclr",
      name = "launch - netcoredbg",
      request = "launch",
      program = function()
        if not selected_dll then
          selected_dll = resolve_dll_path()
        end
        return selected_dll
      end,
      cwd = function()
        return vim.fn.fnamemodify(selected_dll, ":h:h:h:h")
      end,
      env = function()
        local project_root =
            vim.fn.fnamemodify(selected_dll, ":h:h:h:h")

        local settings = get_launch_settings(project_root)

        local env = vim.tbl_extend("force", {
          DOTNET_ENVIRONMENT = "Development",
        }, settings.env)

        if settings.urls then
          env.ASPNETCORE_URLS = settings.urls
        end

        return env
      end,
      justMyCode = true,
    }
  }

  pcall(function()
    require("dap-scope-walker").setup()
  end)
end

return M

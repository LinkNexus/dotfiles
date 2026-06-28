local M = {}
local debugging_utils = require("plugins.debugging.utils")
local dap = require("dap")

function M.setup()
  local js_debug_server = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "js-debug-adapter",
      args = { "${port}" },
    },
  }

  dap.adapters["pwa-node"] = js_debug_server
  dap.adapters["pwa-chrome"] = js_debug_server
  dap.adapters["firefox"] = {
    type = "executable",
    command = debugging_utils.get_mason_adapter("firefox-debug-adapter"),
  }


  local chrome_config = {
    type = "pwa-chrome",
    request = "launch",
    sourceMaps = true,
    webRoot = function()
      local default = vim.fn.getcwd()
      local input = vim.fn.input("Web root (enter to confirm): ", default)
      return input ~= "" and input or default
    end,
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
  }

  local firefox_config = {
    type = "firefox",
    request = "launch",
    reAttach = true,
    sourceMaps = true,
    webRoot = function()
      local default = vim.fn.getcwd()
      local input = vim.fn.input("Web root (enter to confirm): ", default)
      return input ~= "" and input or default
    end,
  }

  -- Base configuration template
  local js_config = {
    type = "pwa-node",
    request = "launch",
    cwd = "${workspaceFolder}",
    sourceMaps = true,
    protocol = "inspector",
    skipFiles = {
      "<node_internals>/**",
      "node_modules/**",
      "**/node_modules/**/*",
    },
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
  }

  for _, language in ipairs({
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
  }) do
    dap.configurations[language] = {
      vim.tbl_extend("force", js_config, {
        name = "Launch file " .. language,
        runtimeExecutable = "tsx",
        program = "${file}",
      }),
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach to Process " .. language,
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
      },

      -- Chrome: dev server
      vim.tbl_extend("force", chrome_config, {
        name = "Chrome: attach dev server " .. language,
        request = "attach",
        port = 9222,
        urlFilter = "http://localhost:*",
      }),
      vim.tbl_extend("force", chrome_config, {
        name = "Chrome: launch dev server " .. language,
        url = function()
          return vim.fn.input("Dev server URL: ", "http://localhost:5173")
        end,
      }),
      -- Chrome: static file
      vim.tbl_extend("force", chrome_config, {
        name = "Chrome: launch static file " .. language,
        url = function()
          local file = vim.fn.expand("%:p")
          return "file://" .. file
        end,
      }),
      -- Firefox: dev server
      vim.tbl_extend("force", firefox_config, {
        name = "Firefox: launch dev server " .. language,
        url = function()
          return vim.fn.input("Dev server URL: ", "http://localhost:5173")
        end,
      }),
      vim.tbl_extend("force", firefox_config, {
        name = "Firefox: attach dev server " .. language,
        request = "attach",
        port = 6000,
        url = "http://localhost:*",
      }),
      -- Firefox: static file
      vim.tbl_extend("force", firefox_config, {
        name = "Firefox: launch static file " .. language,
        url = function()
          local file = vim.fn.expand("%:p")
          return "file://" .. file
        end,
      }),
    }
  end
end

return M

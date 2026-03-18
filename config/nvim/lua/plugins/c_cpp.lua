return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
    },
    lazy = false,
    config = function()
      local dap = require("dap")
      local mason_registry = require("mason-registry")
      local codelldb = mason_registry.get_package("codelldb")
      local codelldb_path = codelldb:get_install_path()
      local codelldb_adapter = codelldb_path .. "/extension/adapter/codelldb"
      vim.notify("codelldb path: " .. codelldb_adapter, vim.log.levels.INFO)
      dap.adapters.codelldb = function(on_adapter)
        local port = 13000 + math.random(0, 5000)
        local stdout = vim.loop.new_pipe(false)
        local stderr = vim.loop.new_pipe(false)

        local handle, pid_or_err = vim.loop.spawn(codelldb_adapter, {
          stdio = { nil, stdout, stderr },
          args = { "--port", tostring(port) },
          detached = true,
        }, function(code)
          stdout:close()
          stderr:close()
          if handle and not handle:is_closing() then
            handle:close()
          end
          if code ~= 0 then
            vim.schedule(function()
              vim.notify("codelldb exited with code " .. code, vim.log.levels.ERROR)
            end)
          end
        end)

        if not handle then
          vim.notify("Error running codelldb: " .. tostring(pid_or_err), vim.log.levels.ERROR)
          return
        end

        -- Give codelldb a brief moment to bind before connecting.
        vim.defer_fn(function()
          on_adapter({
            type = "server",
            host = "127.0.0.1",
            port = port,
          })
        end, 120)
      end

      local configuration = {
        name = "Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      }

      local langs = { "c", "cpp" }

      for _, lang in ipairs(langs) do
        dap.configurations[lang] = (dap.configurations[lang] or {})
        table.insert(dap.configurations[lang], configuration)
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cpp = { "clang_format" },
        c = { "clang_format" },
      },
    },
  },
  {
    "coddingtonbear/neomake-platformio",
  },
  {
    "normen/vim-pio",
  },
}

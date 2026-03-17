return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "racarriga/nvim-dap-ui",
    },
    config = function()
      local dap = require("dap")
      local mason_registry = require("mason-registry")
      local codelldb = mason_registry.get_package("codelldb")
      local codelldb_path = codelldb:get_install_path()
      local codelldb_adapter = codelldb_path .. "/extension/adapter/codelldb"

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb_adapter,
          args = { "--port", "${port}" },
        },
      }

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

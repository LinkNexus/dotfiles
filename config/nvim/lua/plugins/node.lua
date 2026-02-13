return {
  {
    "mfussenegger/nvim-dap",
    opts = function(_, opts)
      local dap = require("dap")

      dap.adapters["pwa-node"].log = true
      dap.configurations.typescript = dap.configurations.javascript or {}
      table.insert(dap.configurations.typescript, {
        type = "pwa-node", -- refers to the adapter above
        request = "launch",
        name = "Launch TS with Bun",
        program = "${file}", -- the TS file you are editing
        cwd = vim.fn.getcwd(),
        runtimeExecutable = "bun", -- Bun runs the TS file directly
        runtimeArgs = { "--bun-debug" }, -- optional arguments
        sourceMaps = true, -- map breakpoints to TS
        console = "integratedTerminal",
      })

      table.insert(dap.configurations.typescript, {
        type = "pwa-node",
        request = "attach",
        name = "Attach to Bun process",
        processId = require("dap.utils").pick_process,
        cwd = vim.fn.getcwd(),
      })
    end,
  },
}

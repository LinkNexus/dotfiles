return {
  {
    'TheLeoP/powershell.nvim',
    ---@type powershell.user_config
    opts = {
      bundle_path = vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services',
    },
  },
  
  -- PowerShell DAP configuration
  {
    'mfussenegger/nvim-dap',
    optional = true,
    opts = function()
      local dap = require('dap')
      
      -- PowerShell debugging adapter configuration
      dap.adapters.ps1 = {
        type = "pipe",
        pipe = function()
          local bundle_path = vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services'
          return vim.fn.serverstart(vim.fn.tempname())
        end,
        -- Alternative configuration using PowerShell Editor Services
        executable = {
          command = 'pwsh',
          args = {
            '-NoLogo',
            '-NoProfile',
            '-Command',
            '& ' .. vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services/PowerShellEditorServices/Start-EditorServices.ps1 -BundledModulesPath ' .. vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services -LogPath ' .. vim.fn.stdpath('cache') .. '/powershell_es.log -SessionDetailsPath ' .. vim.fn.stdpath('cache') .. '/powershell_es_session.json -FeatureFlags @() -AdditionalModules @() -HostName nvim -HostProfileId 0 -HostVersion 1.0.0 -Stdio -BundledModulesPath ' .. vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services'
          },
        }
      }

      -- PowerShell debugging configurations
      dap.configurations.ps1 = {
        {
          name = "PowerShell: Launch Current File",
          type = "ps1",
          request = "launch",
          script = "${file}",
        },
        {
          name = "PowerShell: Launch Script",
          type = "ps1",
          request = "launch",
          script = function()
            return coroutine.create(function(co)
              vim.ui.input({
                prompt = 'Enter path or command to execute, for example: "${workspaceFolder}/src/foo.ps1" or "Invoke-Pester"',
                completion = "file",
              }, function(selected) 
                coroutine.resume(co, selected) 
              end)
            end)
          end,
        },
        {
          name = "PowerShell: Attach to PowerShell Host Process",
          type = "ps1",
          request = "attach",
          processId = "${command:pickProcess}",
        },
      }
    end,
  }
}

return {
  {
    'stevearc/conform.nvim',
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.cs = { 'csharpier' }
    end,
  },
  {
    'seblyng/roslyn.nvim',
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    ft = { 'cs', 'razor' },
    init = function()
      vim.filetype.add({
        extension = {
          razor = 'razor',
          cshtml = 'razor',
        },
      })
    end,
    config = function()
      local rzls_path = vim.fn.expand('$MASON/packages/rzls/libexec')
      local log_dir = vim.fs.dirname(vim.lsp.log.get_filename())

      local cmd = {
        'roslyn',
        '--stdio',
        '--logLevel=Information',
        '--extensionLogDirectory=' .. log_dir,
        '--razorSourceGenerator=' .. vim.fs.joinpath(rzls_path, 'Microsoft.CodeAnalysis.Razor.Compiler.dll'),
        '--razorDesignTimePath=' .. vim.fs.joinpath(rzls_path, 'Targets', 'Microsoft.NET.Sdk.Razor.DesignTime.targets'),
        '--extension',
        vim.fs.joinpath(rzls_path, 'RazorExtension', 'Microsoft.VisualStudioCode.RazorExtension.dll'),
      }

      local ok_handlers, handlers = pcall(require, 'rzls.roslyn_handlers')

      vim.lsp.config('roslyn', {
        cmd = cmd,
        handlers = ok_handlers and handlers or nil,
        settings = {
          ['csharp|inlay_hints'] = {
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
          ['csharp|code_lens'] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      })

      require('roslyn').setup()
    end,
  },

  {
    'ramboe/ramboe-dotnet-utils',
    ft = { 'cs', 'razor' },
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      local dap = require('dap')

      local netcoredbg = vim.fn.stdpath('data') .. '/mason/packages/netcoredbg/netcoredbg'
      if vim.fn.executable(netcoredbg) ~= 1 then
        local shim = vim.fn.stdpath('data') .. '/mason/bin/netcoredbg'
        if vim.fn.executable(shim) == 1 then
          netcoredbg = shim
        end
      end

      local netcoredbg_adapter = {
        type = 'executable',
        command = netcoredbg,
        args = { '--interpreter=vscode' },
      }

      dap.adapters.netcoredbg = netcoredbg_adapter
      dap.adapters.coreclr = netcoredbg_adapter

      local function resolve_dll_path()
        local ok_picker, picker = pcall(require, 'dap-dll-autopicker')
        if ok_picker and type(picker.build_dll_path) == 'function' then
          return picker.build_dll_path()
        end
        return vim.fn.input('Path to .dll: ', vim.fn.getcwd() .. '/', 'file')
      end

      dap.configurations.cs = {
        {
          type = 'coreclr',
          name = 'launch - netcoredbg',
          request = 'launch',
          program = resolve_dll_path,
          cwd = function()
            local dll = resolve_dll_path()
            return vim.fn.fnamemodify(dll, ':h:h:h:h')
          end,
          env = {
            ASPNETCORE_ENVIRONMENT = 'Development',
            DOTNET_ENVIRONMENT = 'Development',
          },
          justMyCode = true,
        },
      }

      pcall(function()
        require('dap-scope-walker').setup()
      end)
    end,
  },

  {
    'nvim-neotest/neotest',
    ft = { 'cs', 'razor' },
    keys = {
      {
        '<leader>tt',
        function()
          require('neotest').run.run()
        end,
        desc = 'Test Nearest',
      },
      {
        '<leader>tT',
        function()
          require('neotest').run.run(vim.fn.expand('%'))
        end,
        desc = 'Test File',
      },
      {
        '<leader>td',
        function()
          require('neotest').run.run({ strategy = 'dap' })
        end,
        desc = 'Debug Nearest Test',
      },
      {
        '<leader>ts',
        function()
          require('neotest').summary.toggle()
        end,
        desc = 'Toggle Test Summary',
      },
      {
        '<leader>to',
        function()
          require('neotest').output.open({ enter = true, auto_close = true })
        end,
        desc = 'Test Output',
      },
      {
        '<leader>tO',
        function()
          require('neotest').output_panel.toggle()
        end,
        desc = 'Toggle Test Output Panel',
      },
    },
    dependencies = {
      'nvim-neotest/nvim-nio',
      'Issafalcon/neotest-dotnet',
    },
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-dotnet'),
        },
      })
    end,
  },
}

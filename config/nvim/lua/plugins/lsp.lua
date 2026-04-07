return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
    },
    config = function()
      local mason_lspconfig = require('mason-lspconfig')
      local ok_fzf, fzf = pcall(require, 'fzf-lua')

      local opts = {
        inlay_hints = {
          enabled = true,
          exclude = { 'vue' },
        },
        codelens = {
          enabled = false,
        },
        folds = {
          enabled = true,
        },
      }

      local diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = 'if_many',
          prefix = '●',
        },
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = ' ',
            [vim.diagnostic.severity.WARN] = ' ',
            [vim.diagnostic.severity.HINT] = ' ',
            [vim.diagnostic.severity.INFO] = ' ',
          },
        },
      }
      vim.diagnostic.config(vim.deepcopy(diagnostics))

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end
      capabilities.workspace = capabilities.workspace or {}
      capabilities.workspace.fileOperations = {
        didRename = true,
        willRename = true,
      }

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
                maxPreload = 2000,
                preloadFileSize = 200,
                ignoreDir = {
                  'LazyVim',
                  '.git',
                  'node_modules',
                },
              },
              diagnostics = {
                workspaceDelay = 3000,
                workspaceRate = 50,
              },
              completion = { callSnippet = 'Replace' },
              codeLens = { enable = true },
              telemetry = { enable = false },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = 'Disable',
                semicolon = 'Disable',
                arrayIndex = 'Disable',
              },
            },
          },
        },
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--inlay-hints',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders',
            '--fallback-style=llvm',
          },
          root_markers = {
            'compile_commands.json',
            'compile_flags.txt',
            'configure.ac',
            'configure.in',
            'config.h.in',
            'meson.build',
            'meson_options.txt',
            'build.ninja',
            'Makefile',
            '.git',
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          capabilities = {
            offsetEncoding = { 'utf-16' },
          },
        },
        basedpyright = {
          settings = {
            python = {
              analysis = {
                autoImportCompletions = true,
                typeCheckingMode = 'basic',
                stubPath = './typings',
              },
            },
          },
        },
        html = {},
        cssls = {},
        jsonls = {},
        vtsls = {},
        biome = {},
      }

      local mason_servers = vim.tbl_keys(servers)
      mason_lspconfig.setup({
        ensure_installed = mason_servers,
        automatic_enable = false,
      })

      for server, opts in pairs(servers) do
        local merged = vim.tbl_deep_extend('force', {
          capabilities = capabilities,
        }, opts or {})
        vim.lsp.config(server, merged)
        vim.lsp.enable(server)
      end

      local function has_method(bufnr, method)
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
          if client:supports_method(method) then
            return true
          end
        end
        return false
      end

      local function map_if_supported(bufnr, lhs, rhs, desc, mode, methods)
        local check = methods
        if type(methods) == 'string' then
          check = { methods }
        end

        if check then
          local ok = false
          for _, method in ipairs(check) do
            local full = method:find('/') and method or 'textDocument/' .. method
            if has_method(bufnr, full) then
              ok = true
              break
            end
          end
          if not ok then
            return
          end
        end

        vim.keymap.set(mode or 'n', lhs, rhs, { buffer = bufnr, desc = desc })
      end

      local function rename_current_file()
        local old_name = vim.api.nvim_buf_get_name(0)
        if old_name == '' then
          return
        end
        vim.ui.input({ prompt = 'New file name: ', default = old_name }, function(new_name)
          if not new_name or new_name == '' or new_name == old_name then
            return
          end
          vim.fn.mkdir(vim.fn.fnamemodify(new_name, ':h'), 'p')
          local ok, err = os.rename(old_name, new_name)
          if not ok then
            vim.notify('Rename failed: ' .. tostring(err), vim.log.levels.ERROR)
            return
          end
          vim.cmd.edit(vim.fn.fnameescape(new_name))
          pcall(vim.lsp.buf.rename)
        end)
      end

      local function jump_reference(forward)
        local word = vim.fn.expand('<cword>')
        if word == '' then
          return
        end
        local pattern = '\\<' .. vim.fn.escape(word, '\\') .. '\\>'
        local flags = forward and 'W' or 'bW'
        vim.fn.search(pattern, flags)
      end

      local function lsp_document_symbols()
        if ok_fzf and fzf.lsp_document_symbols then
          fzf.lsp_document_symbols()
          return
        end
        vim.lsp.buf.document_symbol()
      end

      local function lsp_definitions()
        if ok_fzf and fzf.lsp_definitions then
          fzf.lsp_definitions({ jump1 = false, ignore_current_line = true })
          return
        end
        vim.lsp.buf.definition()
      end

      local function lsp_references()
        if ok_fzf and fzf.lsp_references then
          fzf.lsp_references({ includeDeclaration = false, ignore_current_line = true })
          return
        end
        vim.lsp.buf.references()
      end

      local function lsp_implementations()
        if ok_fzf and fzf.lsp_implementations then
          fzf.lsp_implementations({ jump1 = false })
          return
        end
        vim.lsp.buf.implementation()
      end

      local function lsp_type_definitions()
        if ok_fzf and fzf.lsp_typedefs then
          fzf.lsp_typedefs({ jump1 = false })
          return
        end
        vim.lsp.buf.type_definition()
      end

      local function lsp_workspace_symbols()
        if ok_fzf and fzf.lsp_live_workspace_symbols then
          fzf.lsp_live_workspace_symbols()
          return
        end
        vim.ui.input({ prompt = 'Workspace symbols query: ' }, function(query)
          if query and query ~= '' then
            vim.lsp.buf.workspace_symbol(query)
          end
        end)
      end

      local function call_hierarchy(kind)
        if ok_fzf then
          if kind == 'incoming' and fzf.lsp_incoming_calls then
            fzf.lsp_incoming_calls({ jump1 = false })
            return
          end
          if kind == 'outgoing' and fzf.lsp_outgoing_calls then
            fzf.lsp_outgoing_calls({ jump1 = false })
            return
          end
        end

        local method = kind == 'incoming' and 'callHierarchy/incomingCalls' or 'callHierarchy/outgoingCalls'
        local params = vim.lsp.util.make_position_params(0, 'utf-16')

        vim.lsp.buf_request(0, 'textDocument/prepareCallHierarchy', params, function(err, result)
          if err or not result or vim.tbl_isempty(result) then
            vim.notify('No call hierarchy available', vim.log.levels.INFO)
            return
          end

          local item = result[1]
          vim.lsp.buf_request(0, method, { item = item }, function(err2, calls)
            if err2 or not calls or vim.tbl_isempty(calls) then
              vim.notify('No call hierarchy results', vim.log.levels.INFO)
              return
            end

            local qf_items = {}
            for _, call in ipairs(calls) do
              local target = kind == 'incoming' and call.from or call.to
              qf_items[#qf_items + 1] = {
                filename = vim.uri_to_fname(target.uri),
                lnum = target.range.start.line + 1,
                col = target.range.start.character + 1,
                text = target.name,
              }
            end

            vim.fn.setqflist({}, ' ', {
              title = kind == 'incoming' and 'Incoming Calls' or 'Outgoing Calls',
              items = qf_items,
            })
            vim.cmd.copen()
          end)
        end)
      end

      local function apply_source_fix_all(bufnr)
        local params = vim.lsp.util.make_range_params(0, 'utf-16')
        params.context = {
          diagnostics = vim.diagnostic.get(bufnr),
          only = { 'source.fixAll', 'source.fixAll.clangd' },
          triggerKind = 1,
        }

        local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params, 1500)
        if not results then
          return
        end

        for client_id, res in pairs(results) do
          for _, action in ipairs(res.result or {}) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, 'utf-16')
            end
            if action.command then
              local client = vim.lsp.get_client_by_id(client_id)
              if client then
                client:exec_cmd(action.command, { bufnr = bufnr })
              end
            end
          end
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if client and client.name == 'vtsls' then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          map_if_supported(bufnr, '<leader>cl', '<cmd>LspInfo<cr>', 'Lsp Info')
          map_if_supported(bufnr, 'gd', lsp_definitions, 'Goto Definition', 'n', 'definition')
          map_if_supported(bufnr, 'gr', lsp_references, 'References', 'n')
          map_if_supported(bufnr, 'gI', lsp_implementations, 'Goto Implementation', 'n', 'implementation')
          map_if_supported(bufnr, 'gy', lsp_type_definitions, 'Goto Type Definition', 'n', 'typeDefinition')
          map_if_supported(bufnr, 'gD', vim.lsp.buf.declaration, 'Goto Declaration', 'n', 'declaration')
          map_if_supported(bufnr, 'K', vim.lsp.buf.hover, 'Hover', 'n', 'hover')
          map_if_supported(bufnr, 'gK', vim.lsp.buf.signature_help, 'Signature Help', 'n', 'signatureHelp')
          map_if_supported(bufnr, '<C-k>', vim.lsp.buf.signature_help, 'Signature Help', 'i', 'signatureHelp')
          map_if_supported(bufnr, '<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' }, 'codeAction')
          map_if_supported(bufnr, '<leader>cc', vim.lsp.codelens.run, 'Run Codelens', { 'n', 'x' }, 'codeLens')
          map_if_supported(bufnr, '<leader>cC', vim.lsp.codelens.refresh, 'Refresh & Display Codelens', 'n', 'codeLens')
          map_if_supported(bufnr, '<leader>cR', rename_current_file, 'Rename File', 'n')
          map_if_supported(bufnr, '<leader>cr', vim.lsp.buf.rename, 'Rename', 'n', 'rename')

          map_if_supported(bufnr, '<leader>cA', function()
            vim.lsp.buf.code_action({
              context = { only = { 'source' }, diagnostics = {} },
            })
          end, 'Source Action', 'n', 'codeAction')

          map_if_supported(bufnr, '<leader>co', function()
            vim.lsp.buf.code_action({
              apply = true,
              context = { only = { 'source.organizeImports' }, diagnostics = {} },
            })
          end, 'Organize Imports', 'n', 'codeAction')

          if vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled and vim.lsp.inlay_hint.enable then
            vim.keymap.set('n', '<leader>uh', function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, { buffer = bufnr, desc = 'Toggle Inlay Hints' })
          end

          if vim.bo[bufnr].filetype == 'c' or vim.bo[bufnr].filetype == 'cpp' then
            vim.keymap.set('n', '<leader>ch', '<cmd>LspClangdSwitchSourceHeader<cr>', {
              buffer = bufnr,
              desc = 'Switch Source/Header (C/C++)',
            })

            local fix_group = vim.api.nvim_create_augroup('user-cpp-fixonsave', { clear = false })
            vim.api.nvim_clear_autocmds({ group = fix_group, buffer = bufnr })
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = fix_group,
              buffer = bufnr,
              callback = function()
                apply_source_fix_all(bufnr)
              end,
              desc = 'Apply clangd fixAll before save',
            })
          end

          map_if_supported(bufnr, '<leader>ss', lsp_document_symbols, 'LSP Symbols', 'n', 'documentSymbol')
          map_if_supported(bufnr, '<leader>sS', lsp_workspace_symbols, 'LSP Workspace Symbols', 'n', 'workspace/symbol')
          map_if_supported(bufnr, 'gai', function()
            call_hierarchy('incoming')
          end, 'Calls Incoming', 'n', 'callHierarchy/incomingCalls')
          map_if_supported(bufnr, 'gao', function()
            call_hierarchy('outgoing')
          end, 'Calls Outgoing', 'n', 'callHierarchy/outgoingCalls')

          map_if_supported(bufnr, ']]', function()
            jump_reference(true)
          end, 'Next Reference', 'n')
          map_if_supported(bufnr, '[[', function()
            jump_reference(false)
          end, 'Prev Reference', 'n')
          map_if_supported(bufnr, '<A-n>', function()
            jump_reference(true)
          end, 'Next Reference', 'n')
          map_if_supported(bufnr, '<A-p>', function()
            jump_reference(false)
          end, 'Prev Reference', 'n')

          vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, {
            buffer = bufnr,
            desc = 'Line Diagnostics',
          })
          vim.keymap.set('n', ']d', function()
            vim.diagnostic.jump({
              count = 1,
              on_jump = function(_, jump_bufnr)
                vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = 'cursor', focus = false })
              end,
            })
          end, { buffer = bufnr, desc = 'Next Diagnostic' })
          vim.keymap.set('n', '[d', function()
            vim.diagnostic.jump({
              count = -1,
              on_jump = function(_, jump_bufnr)
                vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = 'cursor', focus = false })
              end,
            })
          end, { buffer = bufnr, desc = 'Prev Diagnostic' })
          vim.keymap.set('n', ']e', function()
            vim.diagnostic.jump({
              count = 1,
              severity = vim.diagnostic.severity.ERROR,
              on_jump = function(_, jump_bufnr)
                vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = 'cursor', focus = false })
              end,
            })
          end, { buffer = bufnr, desc = 'Next Error' })
          vim.keymap.set('n', '[e', function()
            vim.diagnostic.jump({
              count = -1,
              severity = vim.diagnostic.severity.ERROR,
              on_jump = function(_, jump_bufnr)
                vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = 'cursor', focus = false })
              end,
            })
          end, { buffer = bufnr, desc = 'Prev Error' })
          vim.keymap.set('n', ']w', function()
            vim.diagnostic.jump({
              count = 1,
              severity = vim.diagnostic.severity.WARN,
              on_jump = function(_, jump_bufnr)
                vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = 'cursor', focus = false })
              end,
            })
          end, { buffer = bufnr, desc = 'Next Warning' })
          vim.keymap.set('n', '[w', function()
            vim.diagnostic.jump({
              count = -1,
              severity = vim.diagnostic.severity.WARN,
              on_jump = function(_, jump_bufnr)
                vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = 'cursor', focus = false })
              end,
            })
          end, { buffer = bufnr, desc = 'Prev Warning' })

          if opts.inlay_hints.enabled and vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
            local ft = vim.bo[bufnr].filetype
            if not vim.tbl_contains(opts.inlay_hints.exclude, ft) then
              pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
            end
          end

          if opts.codelens.enabled and vim.lsp.codelens and vim.lsp.codelens.refresh then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
              buffer = bufnr,
              callback = vim.lsp.codelens.refresh,
            })
          end

          if opts.folds.enabled and has_method(bufnr, 'textDocument/foldingRange') then
            if vim.o.foldmethod == 'manual' then
              vim.opt_local.foldmethod = 'expr'
              vim.opt_local.foldexpr = 'v:lua.vim.lsp.foldexpr()'
            end
          end
        end,
      })
    end,
  },

  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts_extend = { 'ensure_installed' },
    opts = {
      registries = { 'github:crashdummyy/mason-registry', 'github:mason-org/mason-registry' },
      ensure_installed = {
        'stylua',
        'shfmt',
        'lua-language-server',
        'xmlformatter',
        'csharpier',
        'html-lsp',
        'css-lsp',
        'vtsls',
        'biome',
        'json-lsp',
        'roslyn',
        'rzls',
        'netcoredbg',
        'clangd',
        'black',
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      local mr = require('mason-registry')
      mr:on('package:install:success', function()
        vim.defer_fn(function()
          require('lazy.core.handler.event').trigger({
            event = 'FileType',
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local ok, pkg = pcall(mr.get_package, tool)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },
}

local M = {}

local snacks_ok, Snacks = pcall(require, "snacks")

local function has_method(bufnr, method)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method(method) then
      return true
    end
  end
  return false
end

-- helper that returns true when the buffer has any LSP client attached
local function has_lsp(bufnr)
  return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr }))
end

local function rename_current_file()
  -- Prefer Snacks.rename when available for better integration with file explorers
  if snacks_ok and Snacks and Snacks.rename then
    local ok, _ = pcall(function()
      -- Try a few common API shapes
      if type(Snacks.rename) == "function" then
        Snacks.rename()
        return
      end
      if type(Snacks.rename.rename) == "function" then
        Snacks.rename.rename()
        return
      end
      if type(Snacks.rename.open) == "function" then
        Snacks.rename.open()
        return
      end
    end)
    if ok then
      return
    end
  end

  -- Fallback to builtin rename flow
  local old_name = vim.api.nvim_buf_get_name(0)
  if old_name == "" then
    return
  end
  vim.ui.input({ prompt = "New file name: ", default = old_name }, function(new_name)
    if not new_name or new_name == "" or new_name == old_name then
      return
    end
    vim.fn.mkdir(vim.fn.fnamemodify(new_name, ":h"), "p")
    local ok, err = os.rename(old_name, new_name)
    if not ok then
      vim.notify("Rename failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    vim.cmd.edit(vim.fn.fnameescape(new_name))
    pcall(vim.lsp.buf.rename)
  end)
end

local function jump_reference(forward)
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  local pattern = "\\<" .. vim.fn.escape(word, "\\") .. "\\>"
  local flags = forward and "W" or "bW"
  vim.fn.search(pattern, flags)
end

local function lsp_document_symbols()
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf.lsp_document_symbols then
    fzf.lsp_document_symbols()
    return
  end
  vim.lsp.buf.document_symbol()
end

local function lsp_definitions()
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf.lsp_definitions then
    fzf.lsp_definitions({ jump1 = false, ignore_current_line = true })
    return
  end
  vim.lsp.buf.definition()
end

local function lsp_references()
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf.lsp_references then
    fzf.lsp_references({ includeDeclaration = false, ignore_current_line = true })
    return
  end
  vim.lsp.buf.references()
end

local function lsp_implementations()
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf.lsp_implementations then
    fzf.lsp_implementations({ jump1 = false })
    return
  end
  vim.lsp.buf.implementation()
end

local function lsp_type_definitions()
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf.lsp_typedefs then
    fzf.lsp_typedefs({ jump1 = false })
    return
  end
  vim.lsp.buf.type_definition()
end

local function lsp_workspace_symbols()
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf.lsp_live_workspace_symbols then
    fzf.lsp_live_workspace_symbols()
    return
  end
  vim.ui.input({ prompt = "Workspace symbols query: " }, function(query)
    if query and query ~= "" then
      vim.lsp.buf.workspace_symbol(query)
    end
  end)
end

local function call_hierarchy(kind)
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    if kind == "incoming" and fzf.lsp_incoming_calls then
      fzf.lsp_incoming_calls({ jump1 = false })
      return
    end
    if kind == "outgoing" and fzf.lsp_outgoing_calls then
      fzf.lsp_outgoing_calls({ jump1 = false })
      return
    end
  end

  local method = kind == "incoming" and "callHierarchy/incomingCalls"
      or "callHierarchy/outgoingCalls"
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  vim.lsp.buf_request(0, "textDocument/prepareCallHierarchy", params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      vim.notify("No call hierarchy available", vim.log.levels.INFO)
      return
    end

    local item = result[1]
    vim.lsp.buf_request(0, method, { item = item }, function(err2, calls)
      if err2 or not calls or vim.tbl_isempty(calls) then
        vim.notify("No call hierarchy results", vim.log.levels.INFO)
        return
      end

      local qf_items = {}
      for _, call in ipairs(calls) do
        local target = kind == "incoming" and call.from or call.to
        qf_items[#qf_items + 1] = {
          filename = vim.uri_to_fname(target.uri),
          lnum = target.range.start.line + 1,
          col = target.range.start.character + 1,
          text = target.name,
        }
      end

      vim.fn.setqflist({}, " ", {
        title = kind == "incoming" and "Incoming Calls" or "Outgoing Calls",
        items = qf_items,
      })
      vim.cmd.copen()
    end)
  end)
end

local function apply_source_fix_all(bufnr)
  local params = vim.lsp.util.make_range_params(0, "utf-16")
  params.context = {
    diagnostics = vim.diagnostic.get(bufnr),
    only = { "source.fixAll", "source.fixAll.clangd" },
    triggerKind = 1,
  }

  local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1500)
  if not results then
    return
  end

  for client_id, res in pairs(results) do
    for _, action in ipairs(res.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
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

-- Register mappings declaratively via Snacks.keymap when available, otherwise fallback
local function register_mappings()
  local ok = snacks_ok and Snacks and Snacks.keymap and Snacks.keymap.set
  local set = ok and Snacks.keymap.set or vim.keymap.set

  local lsp_enabled = function(buf)
    return has_lsp(buf)
  end

  -- Basic info
  set("n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "Lsp Info", enabled = lsp_enabled })

  -- Definitions / references / implementations / types
  set("n", "gd", lsp_definitions, { desc = "Goto Definition", lsp = { method = "textDocument/definition" } })
  set("n", "gr", lsp_references, { desc = "References", lsp = { method = "textDocument/references" } })
  set("n", "gI", lsp_implementations, { desc = "Goto Implementation", lsp = { method = "textDocument/implementation" } })
  set("n", "gy", lsp_type_definitions,
    { desc = "Goto Type Definition", lsp = { method = "textDocument/typeDefinition" } })
  set("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration", lsp = { method = "textDocument/declaration" } })

  -- Hover / signature
  set("n", "K", vim.lsp.buf.hover, { desc = "Hover", lsp = { method = "textDocument/hover" } })
  set("n", "gK", vim.lsp.buf.signature_help, { desc = "Signature Help", lsp = { method = "textDocument/signatureHelp" } })
  set("i", "<C-k>", vim.lsp.buf.signature_help,
    { desc = "Signature Help", lsp = { method = "textDocument/signatureHelp" } })

  -- Code actions / codelens / rename / organize
  set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action,
    { desc = "Code Action", lsp = { method = "textDocument/codeAction" } })
  set({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run,
    { desc = "Run Codelens", lsp = { method = "textDocument/codeLens" } })
  set("n", "<leader>cC", vim.lsp.codelens.refresh,
    { desc = "Refresh & Display Codelens", lsp = { method = "textDocument/codeLens" } })
  set("n", "<leader>cR", rename_current_file, { desc = "Rename File", enabled = lsp_enabled })
  set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename", lsp = { method = "textDocument/rename" } })
  set("n", "<leader>cA", function()
    vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
  end, { desc = "Source Action", lsp = { method = "textDocument/codeAction" } })
  set("n", "<leader>co", function()
    vim.lsp.buf.code_action({ apply = true, context = { only = { "source.organizeImports" }, diagnostics = {} } })
  end, { desc = "Organize Imports", lsp = { method = "textDocument/codeAction" } })

  -- Symbols / workspace symbols
  set("n", "<leader>ss", lsp_document_symbols, { desc = "LSP Symbols", lsp = { method = "textDocument/documentSymbol" } })
  set("n", "<leader>sS", lsp_workspace_symbols, { desc = "LSP Workspace Symbols", lsp = { method = "workspace/symbol" } })

  -- Call hierarchy
  set("n", "gai", function() call_hierarchy("incoming") end,
    { desc = "Calls Incoming", lsp = { method = "callHierarchy/prepare" } })
  set("n", "gao", function() call_hierarchy("outgoing") end,
    { desc = "Calls Outgoing", lsp = { method = "callHierarchy/prepare" } })

  -- Reference jumping (only in buffers with LSP attached)
  local ref_opts = { desc = "Next Reference", enabled = lsp_enabled }
  set("n", "]]", function() jump_reference(true) end, ref_opts)
  set("n", "[[", function() jump_reference(false) end, { desc = "Prev Reference", enabled = lsp_enabled })
  set("n", "<A-n>", function() jump_reference(true) end, { desc = "Next Reference", enabled = lsp_enabled })
  set("n", "<A-p>", function() jump_reference(false) end, { desc = "Prev Reference", enabled = lsp_enabled })

  -- Diagnostics (buffer-local behavior preserved via enabled)
  set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics", enabled = lsp_enabled })

  local function diag_jump(next, severity)
    return function()
      local args = { count = next and 1 or -1 }
      if severity then
        args.severity = severity
      end
      args.on_jump = function(_, jump_bufnr)
        vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = "cursor", focus = false })
      end
      vim.diagnostic.jump(args)
    end
  end

  set("n", "]d", diag_jump(true, nil), { desc = "Next Diagnostic", enabled = lsp_enabled })
  set("n", "[d", diag_jump(false, nil), { desc = "Prev Diagnostic", enabled = lsp_enabled })
  set("n", "]e", diag_jump(true, vim.diagnostic.severity.ERROR), { desc = "Next Error", enabled = lsp_enabled })
  set("n", "[e", diag_jump(false, vim.diagnostic.severity.ERROR), { desc = "Prev Error", enabled = lsp_enabled })
  set("n", "]w", diag_jump(true, vim.diagnostic.severity.WARN), { desc = "Next Warning", enabled = lsp_enabled })
  set("n", "[w", diag_jump(false, vim.diagnostic.severity.WARN), { desc = "Prev Warning", enabled = lsp_enabled })

  -- Toggle inlay hints (only if inlay_hint API exists)
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable and vim.lsp.inlay_hint.is_enabled then
    set("n", "<leader>uh", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, { desc = "Toggle Inlay Hints", enabled = lsp_enabled })
  end
end

-- Register mappings once at module load via a compact table
local function register_mappings()
  local ok = snacks_ok and Snacks and Snacks.keymap and Snacks.keymap.set
  local set = ok and Snacks.keymap.set or vim.keymap.set
  local lsp_enabled = function(buf) return has_lsp(buf) end

  local mappings = {
    -- basic info
    { mode = "n",          lhs = "<leader>cl", rhs = "<cmd>LspInfo<cr>",                           opts = { desc = "Lsp Info", enabled = lsp_enabled } },

    -- definitions / references / implementations / types
    { mode = "n",          lhs = "gd",         rhs = lsp_definitions,                              opts = { desc = "Goto Definition", lsp = { method = "textDocument/definition" } } },
    { mode = "n",          lhs = "gr",         rhs = lsp_references,                               opts = { desc = "References", lsp = { method = "textDocument/references" } } },
    { mode = "n",          lhs = "gI",         rhs = lsp_implementations,                          opts = { desc = "Goto Implementation", lsp = { method = "textDocument/implementation" } } },
    { mode = "n",          lhs = "gy",         rhs = lsp_type_definitions,                         opts = { desc = "Goto Type Definition", lsp = { method = "textDocument/typeDefinition" } } },
    { mode = "n",          lhs = "gD",         rhs = vim.lsp.buf.declaration,                      opts = { desc = "Goto Declaration", lsp = { method = "textDocument/declaration" } } },

    -- hover / signature
    { mode = "n",          lhs = "K",          rhs = vim.lsp.buf.hover,                            opts = { desc = "Hover", lsp = { method = "textDocument/hover" } } },
    { mode = "n",          lhs = "gK",         rhs = vim.lsp.buf.signature_help,                   opts = { desc = "Signature Help", lsp = { method = "textDocument/signatureHelp" } } },
    { mode = "i",          lhs = "<C-k>",      rhs = vim.lsp.buf.signature_help,                   opts = { desc = "Signature Help", lsp = { method = "textDocument/signatureHelp" } } },

    -- code actions / codelens / rename / organize
    { mode = { "n", "x" }, lhs = "<leader>ca", rhs = vim.lsp.buf.code_action,                      opts = { desc = "Code Action", lsp = { method = "textDocument/codeAction" } } },
    { mode = { "n", "x" }, lhs = "<leader>cc", rhs = vim.lsp.codelens.run,                         opts = { desc = "Run Codelens", lsp = { method = "textDocument/codeLens" } } },
    { mode = "n",          lhs = "<leader>cC", rhs = function() vim.lsp.codelens.enable(true) end, opts = { desc = "Refresh & Display Codelens", lsp = { method = "textDocument/codeLens" } } },
    { mode = "n",          lhs = "<leader>cR", rhs = rename_current_file,                          opts = { desc = "Rename File", enabled = lsp_enabled } },
    { mode = "n",          lhs = "<leader>cr", rhs = vim.lsp.buf.rename,                           opts = { desc = "Rename", lsp = { method = "textDocument/rename" } } },
    {
      mode = "n",
      lhs = "<leader>cA",
      rhs = function()
        vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
      end,
      opts = { desc = "Source Action", lsp = { method = "textDocument/codeAction" } }
    },
    {
      mode = "n",
      lhs = "<leader>co",
      rhs = function()
        vim.lsp.buf.code_action({ apply = true, context = { only = { "source.organizeImports" }, diagnostics = {} } })
      end,
      opts = { desc = "Organize Imports", lsp = { method = "textDocument/codeAction" } }
    },

    -- symbols / workspace symbols
    { mode = "n", lhs = "<leader>ss", rhs = lsp_document_symbols,                      opts = { desc = "LSP Symbols", lsp = { method = "textDocument/documentSymbol" } } },
    { mode = "n", lhs = "<leader>sS", rhs = lsp_workspace_symbols,                     opts = { desc = "LSP Workspace Symbols", lsp = { method = "workspace/symbol" } } },

    -- call hierarchy
    { mode = "n", lhs = "gai",        rhs = function() call_hierarchy("incoming") end, opts = { desc = "Calls Incoming", lsp = { method = "callHierarchy/prepare" } } },
    { mode = "n", lhs = "gao",        rhs = function() call_hierarchy("outgoing") end, opts = { desc = "Calls Outgoing", lsp = { method = "callHierarchy/prepare" } } },

    -- reference jumping (enabled only when LSP attached)
    { mode = "n", lhs = "]]",         rhs = function() jump_reference(true) end,       opts = { desc = "Next Reference", enabled = lsp_enabled } },
    { mode = "n", lhs = "[[",         rhs = function() jump_reference(false) end,      opts = { desc = "Prev Reference", enabled = lsp_enabled } },
    { mode = "n", lhs = "<A-n>",      rhs = function() jump_reference(true) end,       opts = { desc = "Next Reference", enabled = lsp_enabled } },
    { mode = "n", lhs = "<A-p>",      rhs = function() jump_reference(false) end,      opts = { desc = "Prev Reference", enabled = lsp_enabled } },

    -- diagnostics
    { mode = "n", lhs = "<leader>cd", rhs = vim.diagnostic.open_float,                 opts = { desc = "Line Diagnostics", enabled = lsp_enabled } },
  }

  -- diagnostics jump helpers
  local function diag_jump(next, severity)
    return function()
      local args = { count = next and 1 or -1 }
      if severity then
        args.severity = severity
      end
      args.on_jump = function(_, jump_bufnr)
        vim.diagnostic.open_float({ bufnr = jump_bufnr, scope = "cursor", focus = false })
      end
      vim.diagnostic.jump(args)
    end
  end

  table.insert(mappings,
    { mode = "n", lhs = "]d", rhs = diag_jump(true, nil), opts = { desc = "Next Diagnostic", enabled = lsp_enabled } })
  table.insert(mappings,
    { mode = "n", lhs = "[d", rhs = diag_jump(false, nil), opts = { desc = "Prev Diagnostic", enabled = lsp_enabled } })
  table.insert(mappings,
    { mode = "n", lhs = "]e", rhs = diag_jump(true, vim.diagnostic.severity.ERROR), opts = { desc = "Next Error", enabled = lsp_enabled } })
  table.insert(mappings,
    { mode = "n", lhs = "[e", rhs = diag_jump(false, vim.diagnostic.severity.ERROR), opts = { desc = "Prev Error", enabled = lsp_enabled } })
  table.insert(mappings,
    { mode = "n", lhs = "]w", rhs = diag_jump(true, vim.diagnostic.severity.WARN), opts = { desc = "Next Warning", enabled = lsp_enabled } })
  table.insert(mappings,
    { mode = "n", lhs = "[w", rhs = diag_jump(false, vim.diagnostic.severity.WARN), opts = { desc = "Prev Warning", enabled = lsp_enabled } })

  -- inlay hints toggle if available
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable and vim.lsp.inlay_hint.is_enabled then
    table.insert(mappings, {
      mode = "n",
      lhs = "<leader>uh",
      rhs = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
      end,
      opts = { desc = "Toggle Inlay Hints", enabled = lsp_enabled }
    })
  end

  for _, m in ipairs(mappings) do
    set(m.mode, m.lhs, m.rhs, m.opts)
  end
end

-- register once
register_mappings()

function M.setup(settings)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
    callback = function(event)
      local bufnr = event.buf
      local client = vim.lsp.get_client_by_id(event.data.client_id)

      if client and client.name == "vtsls" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end

      -- C/C++: switch header/source and apply clangd fixAll on save (per-buffer toggle)
      if (vim.bo[bufnr].filetype == "c" or vim.bo[bufnr].filetype == "cpp") and client then
        -- only enable when clangd or when client supports codeAction
        if client.name == "clangd" or (client.supports_method and client:supports_method("textDocument/codeAction")) then
          vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", {
            buffer = bufnr,
            desc = "Switch Source/Header (C/C++)",
          })

          -- default: enabled per-buffer, user can toggle
          vim.b[bufnr].clangd_fix_on_save = true

          local group_name = "user-cpp-fixonsave-" .. bufnr
          local fix_group = vim.api.nvim_create_augroup(group_name, { clear = true })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = fix_group,
            buffer = bufnr,
            callback = function()
              if vim.b[bufnr].clangd_fix_on_save then
                apply_source_fix_all(bufnr)
              end
            end,
            desc = "Apply clangd fixAll before save (buffer-local)",
          })

          -- buffer-local toggle for fix-on-save using Snacks.toggle when available
          local toggle_obj
          if snacks_ok and Snacks and Snacks.toggle and Snacks.toggle.new then
            toggle_obj = Snacks.toggle.new({
              id = "clangd_fix_" .. bufnr,
              name = "clangd fix-on-save",
              get = function() return vim.b[bufnr].clangd_fix_on_save end,
              set = function(state) vim.b[bufnr].clangd_fix_on_save = state end,
            })
          end

          local function toggle_fix()
            if toggle_obj and toggle_obj.toggle then
              toggle_obj:toggle()
              return
            end
            vim.b[bufnr].clangd_fix_on_save = not vim.b[bufnr].clangd_fix_on_save
            vim.notify(("clangd fix-on-save %s"):format(vim.b[bufnr].clangd_fix_on_save and "enabled" or "disabled"),
              vim.log.levels.INFO)
          end

          if snacks_ok and Snacks and Snacks.toggle and Snacks.toggle.new then
            vim.keymap.set("n", "<leader>ct", function()
              if toggle_obj and toggle_obj.toggle then
                toggle_obj:toggle()
              else
                toggle_fix()
              end
            end, { buffer = bufnr, desc = "Toggle clangd fix-on-save" })
          else
            vim.keymap.set("n", "<leader>ct", toggle_fix, { buffer = bufnr, desc = "Toggle clangd fix-on-save" })
          end
        end
      end

      -- Enable inlay hints, codelens and folds based on settings
      if settings.inlay_hints.enabled and vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
        local ft = vim.bo[bufnr].filetype
        if not vim.tbl_contains(settings.inlay_hints.exclude, ft) then
          pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
        end
      end

      if settings.codelens.enabled and vim.lsp.codelens and vim.lsp.codelens.enable then
        vim.lsp.codelens.enable(true)
        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
          buffer = bufnr,
          callback = function() vim.lsp.codelens.enable(true) end,
        })
      end

      if settings.folds.enabled and has_method(bufnr, "textDocument/foldingRange") then
        if vim.o.foldmethod == "manual" then
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr = "v:lua.vim.lsp.foldexpr()"
        end
      end
    end,
  })
end

return M

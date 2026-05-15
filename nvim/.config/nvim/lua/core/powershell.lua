local api = vim.api

local M = {}

local state = {
  sessions = {},
  config = nil,
  debug_term = {
    buf = nil,
    channel = nil,
  },
}

local function default_root_dir(buf)
  local bufname = api.nvim_buf_get_name(buf)
  local dir = vim.fs.dirname(bufname)
  local git_dir = vim.fs.find(".git", { upward = true, path = dir })[1]
  if git_dir then
    return vim.fs.dirname(git_dir)
  end
  return dir
end

local function session_key(root_dir)
  return root_dir or ""
end

local function find_win_for_buf(bufnr)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end
  return nil
end

local function session_paths(root_dir, suffix)
  local cache_dir = vim.fn.stdpath("cache")
  local safe_root = root_dir:gsub("[^%w%._-]", "_")
  local base = string.format("%s/powershell_es.%s.%s", cache_dir, safe_root, suffix)
  return vim.fs.normalize(base .. ".session.json"), vim.fs.normalize(base .. ".log")
end

local function read_session_details(path)
  local ok_read, data = pcall(vim.fn.readfile, path)
  if not ok_read then
    return nil
  end
  local ok_json, decoded = pcall(vim.json.decode, table.concat(data, "\n"))
  if not ok_json then
    return nil
  end
  pcall(vim.fn.delete, path)
  return decoded
end

local function wait_for_session_file(path, cb)
  local function check(remaining)
    if vim.fn.filereadable(path) == 1 then
      local details = read_session_details(path)
      if details then
        cb(details, nil)
      else
        cb(nil, "Could not parse PowerShell session details.")
      end
      return
    end

    if remaining <= 0 then
      cb(nil, string.format("PowerShell session file not found: %s", path))
      return
    end

    vim.defer_fn(function()
      check(remaining - 1)
    end, 500)
  end

  check(60)
end

local function build_cmd(config, opts)
  local file = string.format("%s/PowerShellEditorServices/Start-EditorServices.ps1", config.bundle_path)
  local cmd = {
    config.shell,
    "-NoLogo",
    "-NoProfile",
    "-NonInteractive",
    "-File",
    vim.fs.normalize(file),
    "-HostName",
    "nvim",
    "-HostProfileId",
    "Neovim",
    "-HostVersion",
    "1.0.0",
    "-LogPath",
    opts.log_path,
    "-LogLevel",
    config.lsp_log_level,
    "-BundledModulesPath",
    config.bundle_path,
    "-EnableConsoleRepl",
    "-SessionDetailsPath",
    opts.session_path,
  }

  if opts.debug then
    table.insert(cmd, "-DebugServiceOnly")
  else
    table.insert(cmd, "-LanguageServiceOnly")
  end

  if config.feature_flags and #config.feature_flags > 0 then
    table.insert(cmd, "-FeatureFlags")
    table.insert(cmd, string.format("@(%s)", table.concat(config.feature_flags, ", ")))
  end

  return cmd
end

local function attach_lsp(buf, session)
  local config = state.config
  local details = session.details
  if not details or not details.languageServicePipeName then
    return
  end

  local lsp_config = {
    name = "powershell_es",
    cmd = vim.lsp.rpc.connect(details.languageServicePipeName),
    capabilities = config.capabilities,
    on_attach = config.on_attach,
    settings = config.settings,
    init_options = config.init_options,
    handlers = config.handlers,
    commands = config.commands,
    root_dir = session.root_dir,
  }

  local client_id = vim.lsp.start(lsp_config, {
    bufnr = buf,
    reuse_client = function(client)
      return session.client_id and client.id == session.client_id
    end,
  })

  if client_id then
    session.client_id = client_id
  end
end

local function ensure_session(root_dir)
  local key = session_key(root_dir)
  if state.sessions[key] then
    return state.sessions[key]
  end

  local session_path, log_path = session_paths(root_dir, "lsp")
  local session = {
    root_dir = root_dir,
    session_path = session_path,
    log_path = log_path,
    pending = false,
    pending_buffers = {},
    term_buf = nil,
    term_channel = nil,
    details = nil,
    client_id = nil,
  }

  state.sessions[key] = session
  return session
end

local function start_session(session)
  if session.pending then
    return
  end

  session.pending = true

  local cmd = build_cmd(state.config, {
    session_path = session.session_path,
    log_path = session.log_path,
    debug = false,
  })

  session.term_buf = api.nvim_create_buf(false, false)
  api.nvim_buf_call(session.term_buf, function()
    session.term_channel = vim.fn.jobstart(cmd, { term = true })
  end)

  api.nvim_exec_autocmds("User", {
    pattern = "powershell.nvim-term",
    data = {
      channel = session.term_channel,
      buf = session.term_buf,
    },
  })

  wait_for_session_file(session.session_path, function(details, error_msg)
    session.pending = false
    if error_msg then
      vim.notify(error_msg, vim.log.levels.ERROR)
      return
    end

    session.details = details

    for _, buf in ipairs(session.pending_buffers) do
      if api.nvim_buf_is_valid(buf) then
        attach_lsp(buf, session)
      end
    end

    session.pending_buffers = {}
  end)
end

function M.setup(user_config)
  local config = vim.tbl_deep_extend("force", {
    shell = "pwsh",
    bundle_path = "",
    feature_flags = {},
    lsp_log_level = "Warning",
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    init_options = vim.empty_dict(),
    settings = vim.empty_dict(),
    handlers = nil,
    commands = nil,
    on_attach = nil,
    root_dir = default_root_dir,
  }, user_config or {})

  if config.bundle_path == "" then
    vim.notify("PowerShell bundle_path is not configured.", vim.log.levels.ERROR)
  end

  state.config = config
end

function M.initialize_or_attach(buf)
  local config = state.config
  if not config then
    return
  end

  if vim.bo[buf].buftype == "nofile" then
    return
  end

  local bufname = api.nvim_buf_get_name(buf)
  if bufname == "" then
    return
  end

  local root_dir = config.root_dir(buf)
  local session = ensure_session(root_dir)

  if session.details then
    attach_lsp(buf, session)
    return
  end

  table.insert(session.pending_buffers, buf)

  if not session.pending then
    start_session(session)
  end
end

function M.toggle_term()
  local config = state.config
  if not config then
    return
  end

  local buf = api.nvim_get_current_buf()
  local root_dir = config.root_dir(buf)
  local session = ensure_session(root_dir)

  if not session.term_buf then
    vim.notify("PowerShell extension terminal is not ready.", vim.log.levels.WARN)
    return
  end

  local win = find_win_for_buf(session.term_buf)
  if win then
    api.nvim_win_close(win, true)
    return
  end

  vim.cmd("split")
  api.nvim_set_current_buf(session.term_buf)
end

function M.eval()
  local config = state.config
  if not config then
    return
  end

  local buf = api.nvim_get_current_buf()
  local root_dir = config.root_dir(buf)
  local session = ensure_session(root_dir)

  if not session.term_channel then
    vim.notify("PowerShell extension terminal is not ready.", vim.log.levels.WARN)
    return
  end

  local mode = api.nvim_get_mode().mode
  local lines = nil

  if mode == "n" then
    lines = { api.nvim_get_current_line() }
  elseif mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd.normal({ args = { "\27" }, bang = true })
    local start_row = vim.fn.line("'<") - 1
    local start_col = vim.fn.col("'<") - 1
    local end_row = vim.fn.line("'>") - 1
    local end_col = vim.fn.col("'>")
    lines = api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
  end

  if not lines or #lines == 0 then
    return
  end

  for _, line in ipairs(lines) do
    api.nvim_chan_send(session.term_channel, line .. "\r")
  end
end

function M.setup_dap()
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then
    return
  end

  if not state.config then
    return
  end

  dap.adapters.ps1 = function(on_config, _)
    local session_path = vim.fn.tempname() .. ".json"
    local log_path = vim.fn.tempname() .. ".log"

    local cmd = build_cmd(state.config, {
      session_path = vim.fs.normalize(session_path),
      log_path = vim.fs.normalize(log_path),
      debug = true,
    })

    state.debug_term.buf = api.nvim_create_buf(false, false)
    api.nvim_buf_call(state.debug_term.buf, function()
      state.debug_term.channel = vim.fn.jobstart(cmd, { term = true })
    end)

    api.nvim_exec_autocmds("User", {
      pattern = "powershell.nvim-debug_term",
      data = {
        channel = state.debug_term.channel,
        buf = state.debug_term.buf,
      },
    })

    wait_for_session_file(session_path, function(details, error_msg)
      if error_msg then
        vim.notify(error_msg, vim.log.levels.ERROR)
        return
      end

      on_config({
        type = "pipe",
        pipe = details.debugServicePipeName,
      })
    end)
  end

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
            prompt = "Enter path or command to execute",
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

  dap.listeners.after.initialize["powershell-term"] = function(session)
    session.on_close["powershell-term"] = function()
      local term_buf = state.debug_term.buf
      if term_buf and api.nvim_buf_is_valid(term_buf) then
        pcall(api.nvim_buf_delete, term_buf, { force = true })
      end
      state.debug_term.buf = nil
      state.debug_term.channel = nil
    end
  end

  dap.listeners.after["event_powerShell/sendKeyPress"]["powershell-term"] = function()
    if state.debug_term.channel then
      api.nvim_chan_send(state.debug_term.channel, "p")
    end
  end
end

function M.toggle_debug_term()
  local term_buf = state.debug_term.buf
  if not term_buf or not api.nvim_buf_is_valid(term_buf) then
    vim.notify("PowerShell debug terminal is not ready.", vim.log.levels.WARN)
    return
  end

  local win = find_win_for_buf(term_buf)
  if win then
    api.nvim_win_close(win, true)
    return
  end

  vim.cmd("split")
  api.nvim_set_current_buf(term_buf)
end

return M

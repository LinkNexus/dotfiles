local M = {}

function M.get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  local args_str = type(args) == "table" and table.concat(args, " ") or args

  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str))
    return require("dap.utils").splitstr(new_args)
  end

  return config
end

function M.get_mason_adapter(executable_name)
  local system_path = vim.fn.exepath(executable_name)

  if system_path ~= "" then
    return system_path
  end

  local ok_registry, mr = pcall(require, "mason-registry")

  if ok_registry and mr.is_installed(executable_name) then
    local mason_shim = vim.fn.stdpath("data") .. "/mason/bin/" .. executable_name

    if vim.fn.executable(mason_shim) == 1 then
      return mason_shim
    end
  end

  return executable_name
end

return M

local M = {}

function M.setup(capabilities)
  local mason_lspconfig = require("mason-lspconfig")

  local servers = {
    lua_ls = {
      settings = {
        Lua = {
          workspace = {
            checkThirdParty = false,
            maxPreload = 2000,
            preloadFileSize = 200,
            ignoreDir = {
              ".git",
              "node_modules",
            },
          },
          diagnostics = {
            workspaceDelay = 3000,
            workspaceRate = 50,
          },
          completion = { callSnippet = "Replace" },
          codeLens = { enable = true },
          telemetry = { enable = false },
          hint = {
            enable = true,
            setType = false,
            paramType = true,
            paramName = "Disable",
            semicolon = "Disable",
            arrayIndex = "Disable",
          },
        },
      },
    },
    clangd = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--inlay-hints",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      },
      root_markers = {
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac",
        "configure.in",
        "config.h.in",
        "meson.build",
        "meson_options.txt",
        "build.ninja",
        "Makefile",
        ".git",
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
      capabilities = {
        offsetEncoding = { "utf-16" },
      },
    },
    basedpyright = {
      settings = {
        python = {
          analysis = {
            autoImportCompletions = true,
            typeCheckingMode = "standard",
            stubPath = "./typings",
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
    local merged = vim.tbl_deep_extend("force", {
      capabilities = capabilities,
    }, opts or {})
    vim.lsp.config(server, merged)
    vim.lsp.enable(server)
  end
end

return M

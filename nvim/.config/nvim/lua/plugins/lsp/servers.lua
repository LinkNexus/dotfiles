local M = {}

function M.setup(capabilities)
  local mason_lspconfig = require("mason-lspconfig")

  local mason_servers = {
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
            -- paramName = "Disable",
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
        -- "--query-driver=/run/current-system/sw/bin/avr-gcc",
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
    vtsls = {
      settings = {
        vtsls = {
          experimental = {
            maxInlayHintLength = 30
          }
        },
        typescript = {
          inlayHints = {
            parameterNames = { enabled = "literals" }, -- "none", "literals", "all"
            parameterTypes = { enabled = true },
            variableTypes = { enabled = false },
            propertyDeclarationTypes = { enabled = true },
            functionLikeReturnTypes = { enabled = false },
            enumMemberValues = { enabled = true },
          }
        },
        javascript = {
          inlayHints = {
            parameterNames = { enabled = "all" },
            parameterTypes = { enabled = true },
            variableTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            enumMemberValues = { enabled = true },
          },
        },
      }
    },
    biome = {},
    tailwindcss = {},
    docker_compose_language_service = {},
    docker_language_server = {},
    dockerls = {},
  }

  local other_servers = {
    roslyn_ls = {
      settings = {
        ["csharp|inlay_hints"] = {
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
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },
      },
    },
  }

  require("core.pwsh").setup({
    bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
    shell = "pwsh",
    capabilities = capabilities,
    settings = {
      powershell = {
        codeFormatting = {
          preset = "OTBS",
        },
        scriptAnalysis = {
          enable = true,
        },
      },
    },
  })

  local mason_severs_keys = vim.tbl_keys(mason_servers)
  mason_lspconfig.setup({
    ensure_installed = mason_severs_keys,
    automatic_enable = false,
  })

  for server, opts in pairs(vim.tbl_extend("force", mason_servers, other_servers)) do
    local merged = vim.tbl_deep_extend("force", {
      capabilities = capabilities,
    }, opts or {})
    vim.lsp.config(server, merged)
    vim.lsp.enable(server)
  end
end

return M

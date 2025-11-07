return {
  -- {
  --   "neovim/nvim-lspconfig",
  --   ft = { "php" }, -- Ensure it loads for PHP files
  --   opts = {
  --     servers = {
  --       -- Disable phpactor completely
  --       phpactor = false,

  --       intelephense = {
  --         -- Ensure proper command and filetypes
  --         cmd = { "intelephense", "--stdio" },
  --         settings = {
  --           intelephense = {
  --             files = {
  --               maxSize = 5000000, -- 5 MB
  --               exclude = {
  --                 "**/vendor/**",
  --                 "**/node_modules/**",
  --                 "**/.git/**",
  --                 "**/storage/**",
  --                 "**/bootstrap/cache/**",
  --               },
  --             },
  --             -- Disable formatting (use Pint instead)
  --             format = {
  --               enable = false,
  --             },
  --             -- Enhanced completion settings
  --             completion = {
  --               insertUseDeclaration = true,
  --               fullyQualifyGlobalConstantsAndFunctions = false,
  --               triggerParameterHints = true,
  --               maxItems = 100,
  --             },
  --             -- Enable diagnostics
  --             diagnostics = {
  --               enable = true,
  --               run = "onType",
  --               embeddedLanguages = true,
  --             },
  --             -- Better PHPDoc support
  --             phpdoc = {
  --               returnVoid = true,
  --               textFormat = "snippet",
  --             },
  --             -- Exclude vendor from references and rename
  --             references = {
  --               exclude = { "**/vendor/**" },
  --             },
  --             rename = {
  --               exclude = { "**/vendor/**" },
  --             },
  --           },
  --         },
  --       },
  --     },
  --   },
  -- },

  -- PHP CodeSniffer for linting and formatting
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.php = { "phpcs" }

      opts.linters = opts.linters or {}
      opts.linters.phpcs = {
        command = "phpcs",
        args = function()
          local args = {}

          -- Try to find project-specific configuration files
          local config_files = {
            ".php-cs.xml",
            "phpcs.xml",
            ".phpcs.xml",
            "phpcs.xml.dist",
          }

          local root_dir = require("conform.util").root_file({
            "composer.json",
            ".git",
            "phpcs.xml",
            ".phpcs.xml",
          })()

          if root_dir then
            for _, config_file in ipairs(config_files) do
              local config_path = root_dir .. "/" .. config_file
              if vim.fn.filereadable(config_path) == 1 then
                table.insert(args, "--standard=" .. config_path)
                break
              end
            end
          end

          -- Add the filename to be linted
          table.insert(args, "$FILENAME")
          return args
        end,
        stdin = false, -- phpcs needs a file, not stdin
        ignore_exitcode = true, -- phpcs returns non-zero exit codes for warnings/errors
        cwd = function()
          -- Set working directory to project root
          return require("conform.util").root_file({
            "composer.json",
            ".git",
            ".php-cs.xml",
            "phpcs.xml",
            ".phpcs.xml",
          })()
        end,
      }
    end,
  },
  -- General PHP plugins and configurations
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        php = { "pint" },
      },
    },
  },

  -- {
  --   "mfussenegger/nvim-lint",
  --   opts = function(_, opts)
  --     opts.linters_by_ft.php = { "phpcs" }
  --     opts.linters.phpcs = {
  --       command = "phpcs",
  --       args = {
  --         "$FILENAME",
  --       },
  --       stdin = false, -- phpcs needs a file, not stdin
  --       ignore_exitcode = true, -- phpcs returns non-zero exit codes for warnings/errors
  --     }
  --   end,
  -- },
  --
  -- Laravel specific plugins and configurations
  {
    "adalessa/laravel.nvim",
    dependencies = {
      "tpope/vim-dotenv",
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "ravitemer/mcphub.nvim", -- optional
    },
    cmd = { "Laravel" },
    keys = {
      -- {
      --   "<leader>ll",
      --   function()
      --     Laravel.pickers.laravel()
      --   end,
      --   desc = "Laravel: Open Laravel Picker",
      -- },
      -- {
      --   "<c-g>",
      --   function()
      --     Laravel.commands.run("view:finder")
      --   end,
      --   desc = "Laravel: Open View Finder",
      -- },
      -- {
      --   "<leader>la",
      --   function()
      --     Laravel.pickers.artisan()
      --   end,
      --   desc = "Laravel: Open Artisan Picker",
      -- },
      -- {
      --   "<leader>lt",
      --   function()
      --     Laravel.commands.run("actions")
      --   end,
      --   desc = "Laravel: Open Actions Picker",
      -- },
      -- {
      --   "<leader>lr",
      --   function()
      --     Laravel.pickers.routes()
      --   end,
      --   desc = "Laravel: Open Routes Picker",
      -- },
      -- {
      --   "<leader>lh",
      --   function()
      --     Laravel.run("artisan docs")
      --   end,
      --   desc = "Laravel: Open Documentation",
      -- },
      -- {
      --   "<leader>lm",
      --   function()
      --     Laravel.pickers.make()
      --   end,
      --   desc = "Laravel: Open Make Picker",
      -- },
      -- {
      --   "<leader>lc",
      --   function()
      --     Laravel.pickers.commands()
      --   end,
      --   desc = "Laravel: Open Commands Picker",
      -- },
      -- {
      --   "<leader>lo",
      --   function()
      --     Laravel.pickers.resources()
      --   end,
      --   desc = "Laravel: Open Resources Picker",
      -- },
      -- {
      --   "<leader>lp",
      --   function()
      --     Laravel.commands.run("command_center")
      --   end,
      --   desc = "Laravel: Open Command Center",
      -- },
      {
        "gf",
        function()
          local ok, res = pcall(function()
            if Laravel.app("gf").cursorOnResource() then
              return "<cmd>lua Laravel.commands.run('gf')<cr>"
            end
          end)
          if not ok or not res then
            return "gf"
          end
          return res
        end,
        expr = true,
        noremap = true,
      },
    },
    event = { "VeryLazy" },
    opts = {
      lsp_server = "phpactor", -- "phpactor | intelephense"
      features = {
        pickers = {
          provider = "snacks", -- "snacks | telescope | fzf-lua | ui-select"
        },
        completion_provider = { enable = true },
        route_info = { enable = false }, -- Disabled to prevent error
        model_info = { enable = true },
        override = { enable = true },
      },
      completion = {
        enable = true,
        provider = "blink.cmp", -- Ensure Laravel autocompletion is enabled for blink.cmp
      },
    },
  },
  -- Blade formatter for Laravel Blade templates
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Ensure formatters_by_ft exists
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      -- Add blade formatter (will merge with existing PHP config from other file)
      opts.formatters_by_ft.blade = { "blade_formatter" }

      -- Configure blade formatter (only if not already configured)
      opts.formatters = opts.formatters or {}
      if not opts.formatters.blade_formatter then
        opts.formatters.blade_formatter = {
          command = "blade-formatter",
          args = {
            "--stdin",
            "$FILENAME",
          },
          stdin = true,
          cwd = require("conform.util").root_file({
            "composer.json",
            ".git",
            "package.json",
            ".bladeformatterrc",
            "blade-formatter.json",
          }),
        }
      end
    end,
  },
  {
    "ricardoramirezr/blade-nav.nvim",
    dependencies = { -- totally optional
      "saghen/blink.cmp", -- if using blink.cmp
    },
    ft = { "blade", "php" }, -- optional, improves startup time
    opts = {
      -- This applies for nvim-cmp and coq, for blink refer to the configuration of this plugin
      close_tag_on_complete = true, -- default: true
    },
    config = function(_, opts)
      require("blade-nav").setup(opts)

      -- Optional: Configure global settings for blade-nav
      vim.g.blade_nav = {
        -- Add additional Laravel component paths if needed
        laravel_components = {
          -- "resources/views/common",
          -- "resources/views/components",
        },
        -- Set to false if you don't want routes completion
        include_routes = true,
      }
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true, -- Make this optional since it's already configured in blink-compat.lua
    opts = function(_, opts)
      -- Ensure sources exist
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      opts.sources.providers = opts.sources.providers or {}

      -- Add blade-nav to the default sources if not already present
      local sources = opts.sources.default
      if not vim.tbl_contains(sources, "blade-nav") then
        table.insert(sources, "blade-nav")
      end

      -- Configure blade-nav provider
      opts.sources.providers["blade-nav"] = {
        module = "blade-nav.blink",
        opts = {
          close_tag_on_complete = true, -- default: true,
        },
      }

      return opts
    end,
  },
}

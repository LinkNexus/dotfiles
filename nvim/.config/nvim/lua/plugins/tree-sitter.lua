return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
      enable_indent = true,
      ensure_installed = {
        "astro",
        "bash",
        "c",
        "cpp",
        "css",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "cmake",
        "c_sharp",
      },
      textobjects = {
        select = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          ["al"] = "@loop.outer",
          ["il"] = "@loop.inner",
          ["ai"] = "@conditional.outer",
          ["ii"] = "@conditional.inner",
          ["am"] = "@call.outer",
          ["im"] = "@call.inner",
          ["as"] = "@statement.outer",
        },
        move_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        move_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        move_prev_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        move_prev_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_prev = {
          ["<leader>A"] = "@parameter.inner",
        },
        lsp_peek = {
          ["<leader>df"] = "@function.outer",
          ["<leader>dF"] = "@class.outer",
        },
      },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      local missing_module_notified = {}

      local function require_textobjects_module(name)
        local ok, mod = pcall(require, "nvim-treesitter-textobjects." .. name)
        if ok then
          return mod
        end

        ok, mod = pcall(require, "nvim-treesitter.textobjects." .. name)
        if ok then
          return mod
        end

        if not missing_module_notified[name] then
          missing_module_notified[name] = true
          vim.schedule(function()
            vim.notify("Missing treesitter textobjects module: " .. name, vim.log.levels.WARN)
          end)
        end
        return nil
      end

      ts.setup({
        install_dir = opts.install_dir,
      })

      if opts.ensure_installed and #opts.ensure_installed > 0 then
        ts.install(opts.ensure_installed)
      end

      local ts_group = vim.api.nvim_create_augroup("user-treesitter-filetype", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = ts_group,
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
          if opts.enable_indent then
            pcall(function()
              vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end)
          end
        end,
      })

      local textobjects = opts.textobjects or {}
      for lhs, query in pairs(textobjects.select or {}) do
        vim.keymap.set({ "o", "x" }, lhs, function()
          local mod = require_textobjects_module("select")
          if mod and mod.select_textobject then
            mod.select_textobject(query, "textobjects")
          end
        end, { desc = "Select " .. query })
      end
      for lhs, query in pairs(textobjects.swap_next or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("swap")
          if mod and mod.swap_next then
            mod.swap_next(query)
          end
        end, { desc = "Swap next " .. query })
      end
      for lhs, query in pairs(textobjects.swap_prev or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("swap")
          if mod and mod.swap_previous then
            mod.swap_previous(query)
          end
        end, { desc = "Swap previous " .. query })
      end
      for lhs, query in pairs(textobjects.move_next_start or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("move")
          if mod and mod.goto_next_start then
            mod.goto_next_start(query)
          end
        end, { desc = "Go to next " .. query .. " start" })
      end
      for lhs, query in pairs(textobjects.move_next_end or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("move")
          if mod and mod.goto_next_end then
            mod.goto_next_end(query)
          end
        end, { desc = "Go to next " .. query .. " end" })
      end
      for lhs, query in pairs(textobjects.move_prev_start or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("move")
          if mod and mod.goto_previous_start then
            mod.goto_previous_start(query)
          end
        end, { desc = "Go to previous " .. query .. " start" })
      end
      for lhs, query in pairs(textobjects.move_prev_end or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("move")
          if mod and mod.goto_previous_end then
            mod.goto_previous_end(query)
          end
        end, { desc = "Go to previous " .. query .. " end" })
      end
      for lhs, query in pairs(textobjects.lsp_peek or {}) do
        vim.keymap.set("n", lhs, function()
          local mod = require_textobjects_module("lsp_interop")
          if mod and mod.peek_definition_code then
            mod.peek_definition_code(query)
          else
            vim.lsp.buf.definition()
          end
        end, { desc = "Peek definition " .. query })
      end
    end,
  },
  {
    "MeanderingProgrammer/treesitter-modules.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      multiwindow = true,
    },
  },
}

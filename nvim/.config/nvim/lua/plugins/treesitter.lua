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
        "powershell",
      },
    },
    config = function(opts)
      vim.g.no_plugin_maps = true

      local ts = require("nvim-treesitter")
      ts.setup({
        install_dir = opts.install_dir,
      })

      if opts.ensure_installed and #opts.ensure_installed > 0 then
        ts.install(opts.ensure_installed)
      end

      local ts_group = vim.api.nvim_create_augroup("user-tressitter-filetype", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = ts_group,
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
          pcall(function()
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)
        end,
      })
    end,
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

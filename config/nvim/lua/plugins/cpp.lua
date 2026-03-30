return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "c", "cpp", "cmake" })
        end,
    },

    {
        "p00f/clangd_extensions.nvim",
        ft = { "c", "cpp", "objc", "objcpp" },
        opts = {
            inlay_hints = {
                inline = true,
            },
        },
    },

    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            formatters_by_ft = {
                c = { "clang_format" },
                cpp = { "clang_format" },
                objc = { "clang_format" },
                objcpp = { "clang_format" },
            },
            format_on_save = {
                timeout_ms = 800,
                lsp_fallback = true,
            },
        },
    },

    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "clangd",
                "clang-format",
                "codelldb",
            })
        end,
    },

    {
        dir = Get_local_plugin_path("cpp_header_sync.nvim"),
        opts = {}
    }

}

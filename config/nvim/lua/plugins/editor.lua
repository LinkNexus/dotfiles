return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {},
        keys = {
            {
                "<leader>qs",
                function()
                    require("persistence").load()
                end,
                desc = "Restore session for current dir",
            },
            {
                "<leader>qS",
                function()
                    require("persistence").select()
                end,
                desc = "Select session to restore",
            },
            {
                "<leader>ql",
                function()
                    require("persistence").load({ last = true })
                end,
                desc = "Restore last Session",
            },
            {
                "<leader>qd",
                function()
                    require("persistence").stop()
                end,
                desc = "Stop persistence for current session (session won't be saved on exit)",
            },
        },
    },
    {
        "nvim-mini/mini.ai",
        event = "VeryLazy",
        opts = function()
            local ai = require("mini.ai")
            return {
                n_lines = 500,
                custom_textobjects = {
                    o = ai.gen_spec.treesitter({
                        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
                    }),
                    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
                    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
                    t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
                    d = { "%f[%d]%d+" },
                    e = {
                        {
                            "%u[%l%d]+%f[^%l%d]",
                            "%f[%S][%l%d]+%f[^%l%d]",
                            "%f[%P][%l%d]+%f[^%l%d]",
                            "^[%l%d]+%f[^%l%d]",
                        },
                        "^().*()$",
                    },
                    g = function()
                        local from = { line = 1, col = 1 }
                        local to = { line = vim.fn.line("$"), col = vim.fn.getline("$"):len() }
                        return { from = from, to = to }
                    end,
                    u = ai.gen_spec.function_call(),
                    U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
                },
            }
        end,
    },
    {
        "folke/ts-comments.nvim",
        event = "VeryLazy",
        opts = {},
    },
    {
        "nvim-mini/mini.pairs",
        event = "VeryLazy",
        opts = {
            modes = { insert = true, command = true, terminal = false },
            skip_next = [=[[%w%%%'%[%%"%.%`%$]]=],
            skip_ts = { "string" },
            skip_unbalanced = true,
            markdown = true,
        },
    },
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "LspAttach",
        priority = 1000,
        config = function()
            require("tiny-inline-diagnostic").setup({
                -- ...
                signs = {
                    left = "",
                    right = "",
                    diag = "●",
                    arrow = "    ",
                    up_arrow = "    ",
                    vertical = " │",
                    vertical_end = " └",
                },
                blend = {
                    factor = 0.22,
                },
                -- ...
            })
            vim.diagnostic.config({ virtual_text = false })
        end,
    },

    {
        "tpope/vim-sleuth"
    },
}

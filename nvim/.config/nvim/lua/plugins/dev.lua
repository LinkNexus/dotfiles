return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        -- { path = "wezterm-types", mods = { "wezterm" } },
      },
      enabled = function(root_dir)
        return (not vim.uv.fs_stat(root_dir .. "/.luarc.json"))
          and (vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled)
      end,
    },
  },
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "saghen/blink.cmp",
    enabled = false,
    optional = true,
  },
  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    opts = function()
      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local kind_icons = {
        Text = "T ",
        Method = "M ",
        Function = "F ",
        Constructor = "C ",
        Field = "Fd",
        Variable = "V ",
        Class = "Cl",
        Interface = "I ",
        Module = "Md",
        Property = "P ",
        Unit = "U ",
        Value = "Val",
        Enum = "E ",
        Keyword = "K ",
        Snippet = "S ",
        Color = "Co",
        File = "Fi",
        Reference = "R ",
        Folder = "Fo",
        EnumMember = "Em",
        Constant = "Ct",
        Struct = "St",
        Event = "Ev",
        Operator = "Op",
        TypeParameter = "Tp",
      }

      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        preselect = cmp.PreselectMode.Item,
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<S-CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ["<C-CR>"] = function(fallback)
            cmp.abort()
            fallback()
          end,
          ["<Tab>"] = function(fallback)
            local ok_copilot, copilot_suggestion = pcall(require, "copilot.suggestion")
            if ok_copilot and copilot_suggestion.is_visible() then
              copilot_suggestion.accept()
            elseif cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end,
          ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end,
        }),
        sources = cmp.config.sources({
          { name = "lazydev" },
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          format = function(_, item)
            local icon = kind_icons[item.kind]
            if icon then
              item.kind = icon .. item.kind
            end
            return item
          end,
        },
        experimental = {
          ghost_text = vim.g.ai_cmp and { hl_group = "CmpGhostText" } or false,
        },
      }
    end,
    config = function(_, opts)
      require("cmp").setup(opts)
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
    end,
  },
}

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    dependencies = {
      {
        "copilotlsp-nvim/copilot-lsp",
        init = function()
          vim.g.copilot_nes_debounce = 500
        end,
      },
    },
    opts = {
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          accept = false,
          accept_word = "<M-w>",
          accept_line = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      nes = {
        enabled = false,
        keymap = {
          accept_and_goto = "<M-Right>",
          accept = false,
          dismiss = "<M-Left>",
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        help = false,
        gitcommit = true,
        gitrebase = false,
        ["."] = false,
      },
      server_opts_overrides = {
        offset_encoding = "utf-16",
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },
}

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle filesystem reveal left<cr>", desc = "Explorer (Neo-tree)" },
      { "<leader>E", "<cmd>Neotree focus filesystem left<cr>", desc = "Explorer Focus" },
      { "<leader>fe", "<cmd>Neotree reveal<cr>", desc = "Reveal Current File" },
      { "<leader>eb", "<cmd>Neotree toggle buffers left<cr>", desc = "Explorer Buffers" },
      { "<leader>eg", "<cmd>Neotree toggle git_status left<cr>", desc = "Explorer Git Status" },
      { "<leader>ef", "<cmd>Neotree toggle filesystem left<cr>", desc = "Explorer Filesystem" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      source_selector = {
        winbar = true,
        statusline = false,
      },
      enable_git_status = true,
      enable_diagnostics = true,
      use_popups_for_input = true,
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = ">",
          expander_expanded = "v",
          expander_highlight = "NeoTreeExpander",
        },
      },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        window = {
          mappings = {
            ["."] = "toggle_hidden",
          },
        },
        use_libuv_file_watcher = true,
        group_empty_dirs = false,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = { ".DS_Store" },
        },
      },
      window = {
        position = "left",
        width = 40,
        mappings = {
          ["<space>"] = "none",
          ["l"] = "open",
          ["h"] = "close_node",
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path)
            end,
            desc = "Copy Path to Clipboard",
          },
          ["A"] = {
            "add_directory",
            config = {
              show_path = "relative",
            },
          },
          ["d"] = "delete",
          ["r"] = "rename",
          ["c"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["R"] = "refresh",
        },
      },
    },
  },
}

return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        globalstatus = true,
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        disabled_filetypes = { statusline = { "snacks_dashboard" } },
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
        },
        lualine_b = {
          {
            'branch',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
          { 'diff' },
          { 'diagnostics' },
        },
        lualine_c = {
          {
            'filename',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
        },
        lualine_x = {
          {
            'encoding',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
          {
            'fileformat',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
          {
            'filetype',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
        },
        lualine_y = {
          {
            'progress',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
        },
        lualine_z = {
          {
            'location',
            fmt = function(str)
              return '[' .. str .. ']'
            end,
          },
        },
      },
    },
  },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      spec = {
        {
          mode = { 'n', 'x' },
          { '<leader><tab>', group = 'tabs' },
          { '<leader>n',     group = 'notifications' },
          { '<leader>c',     group = 'code' },
          { '<leader>d',     group = 'debug' },
          { '<leader>dp',    group = 'profiler' },
          { '<leader>f',     group = 'file/find' },
          { '<leader>t',     group = 'test' },
          { '<leader>q',     group = 'quit/session' },
          { '<leader>g',     group = 'git' },
          { '<leader>gh',    group = 'hunks' },
          { '<leader>gP',    group = 'pull requests' },
          { '[',             group = 'prev' },
          { ']',             group = 'next' },
          { 'g',             group = 'goto' },
          { 'gs',            group = 'surround' },
          { 'z',             group = 'fold' },
          {
            '<leader>b',
            group = 'buffer',
            expand = function()
              return require('which-key.extras').expand.buf()
            end,
          },
          { '<leader>s', group = 'search' },
          {
            '<leader>w',
            group = 'windows',
            proxy = '<c-w>',
            expand = function()
              return require('which-key.extras').expand.win()
            end,
          },
          { 'gx',        desc = 'Open with system app' },
        },
      },
    },
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show({ global = false })
        end,
        desc = 'Buffer Local Keymaps (which-key)',
      },
    },
  },
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>nh', '<cmd>Noice history<cr>', desc = 'Notification History' },
      { '<leader>nd', '<cmd>Noice dismiss<cr>', desc = 'Dismiss Notifications' },
    },
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      routes = {
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d+L, %d+B' },
              { find = '; after #%d+' },
              { find = '; before #%d+' },
            },
          },
          view = 'mini',
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
      views = {
        mini = {
          position = {
            row = -2,
          },
          win_options = {
            winblend = 0,
          },
        },
      },
    },
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
  },
  {
    'rcarriga/nvim-notify',
    lazy = true,
    opts = {
      background_colour = '#000000',
    },
  },
  {
    'stevearc/dressing.nvim',
    lazy = true,
    opts = {},
    init = function()
      vim.ui.input = function(...)
        require('lazy').load({ plugins = { 'dressing.nvim' } })
        return vim.ui.input(...)
      end
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.cmd.colorscheme("carbonfox")
        vim.api.nvim_set_option_value("background", "dark", {})
      end,
      set_light_mode = function()
        vim.cmd.colorscheme("dayfox")
        vim.api.nvim_set_option_value("background", "light", {})
      end,
      update_interval = 3000
    }
  }
}

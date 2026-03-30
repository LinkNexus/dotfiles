return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '▎' },
        change = { text = '▎' },
        delete = { text = '' },
        topdelete = { text = '' },
        changedelete = { text = '▎' },
        untracked = { text = '▎' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        map('n', ']h', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, 'Next Hunk')

        map('n', '[h', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, 'Prev Hunk')

        map('n', ']H', function()
          gs.nav_hunk('last')
        end, 'Last Hunk')

        map('n', '[H', function()
          gs.nav_hunk('first')
        end, 'First Hunk')

        map({ 'n', 'x' }, '<leader>ghs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
        map({ 'n', 'x' }, '<leader>ghr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
        map('n', '<leader>ghS', gs.stage_buffer, 'Stage Buffer')
        map('n', '<leader>ghu', gs.undo_stage_hunk, 'Undo Stage Hunk')
        map('n', '<leader>ghR', gs.reset_buffer, 'Reset Buffer')
        map('n', '<leader>ghp', gs.preview_hunk_inline, 'Preview Hunk')
        map('n', '<leader>ghb', function()
          gs.blame_line({ full = true })
        end, 'Blame Line')
        map('n', '<leader>ghB', gs.blame, 'Blame Buffer')
        map('n', '<leader>ghd', gs.diffthis, 'Diff This')
        map('n', '<leader>ghD', function()
          gs.diffthis('~')
        end, 'Diff This ~')
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'Select Hunk')
      end,
    },
  },

  {
    'ibhagwan/fzf-lua',
    optional = true,
    keys = {
      { '<leader>gc', '<cmd>FzfLua git_commits<cr>', desc = 'Commits' },
      { '<leader>gd', '<cmd>FzfLua git_diff<cr>', desc = 'Git Diff (files)' },
      { '<leader>gl', '<cmd>FzfLua git_commits<cr>', desc = 'Commits' },
      { '<leader>gs', '<cmd>FzfLua git_status<cr>', desc = 'Status' },
      { '<leader>gS', '<cmd>FzfLua git_stash<cr>', desc = 'Stash' },
      { '<leader>gb', '<cmd>Gitsigns blame_line<cr>', desc = 'Blame Line' },
      { '<leader>gB', '<cmd>Gitsigns toggle_current_line_blame<cr>', desc = 'Toggle Line Blame' },
    },
  },
}

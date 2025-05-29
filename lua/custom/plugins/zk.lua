-- See https://github.com/zk-org/zk-nvim
--
return {
  'zk-org/zk-nvim',
  config = function()
    vim.lsp.enable 'zk'
    require('zk').setup {
      picker = 'telescope',
    }

    vim.keymap.set('n', '<leader>zn', function()
      require('zk.commands').get 'ZkNew' { title = vim.fn.input 'New Note Title: ' }
    end, { desc = 'Create a [N]ew note after asking for its title.' })

    vim.api.nvim_set_keymap('n', '<leader>zl', '<Cmd>ZkNotes<CR>', { desc = '[L]ist notes' })
  end,
}

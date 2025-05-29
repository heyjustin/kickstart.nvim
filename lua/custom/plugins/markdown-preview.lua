return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  build = 'cd app && yarn install',
  init = function()
    vim.g.mkdp_filetypes = { 'markdown' }
    vim.g.mkdp_markdown_css = '/Users/juswalsh/.config/nvim/lua/custom/plugins/markdown-style.css'
  end,
  ft = { 'markdown' },
  vim.api.nvim_set_keymap('n', '<leader>mp', '<Plug>MarkdownPreviewToggle', { desc = 'Toggle [m]arkdown [p]review' }),
}

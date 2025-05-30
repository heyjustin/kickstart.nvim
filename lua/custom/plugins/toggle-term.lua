return {
  'akinsho/toggleterm.nvim',
  version = '*',
  opts = {},
  config = function()
    require('toggleterm').setup {
      open_mapping = [[<c-\>]], -- Key to toggle terminal visibility
    }
  end,
}

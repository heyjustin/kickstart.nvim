-- markdown.nvim settings
local markdown_settings = {
  no_default_key_mappings = 1,
  folding_disabled = 0,
  folding_style_pythonic = 1,
  folding_level = 2,
  toc_autofit = 1,
  conceal = 0,
  conceal_code_blocks = 0,
  no_extensions_in_markdown = 1,
  autowrite = 1,
  follow_anchor = 1,
  auto_insert_bullets = 0,
  new_list_item_indent = 0,
}

for key, value in pairs(markdown_settings) do
  vim.g['vim_markdown_' .. key] = value
end

-- FileType autocmd for markdown files
vim.opt_local.conceallevel = 0
vim.bo.textwidth = 175
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.autoindent = true

-- Arrow abbreviations/autocorrection
local arrows = {
  ['>>'] = '→',
  ['<<'] = '←',
  ['^^'] = '↑',
  ['VV'] = '↓',
  ['teh'] = 'the',
}
for key, val in pairs(arrows) do
  vim.cmd(string.format('iabbrev %s %s', key, val))
end

-- Paste image functionality - required `brew install pngpaste`
local function paste_image()
  -- Create images directory if it doesn't exist
  local file_dir = vim.fn.expand '%:p:h'
  local img_dir = file_dir .. '/images'

  if vim.fn.isdirectory(img_dir) == 0 then
    vim.fn.mkdir(img_dir, 'p')
  end

  -- Ask for image name
  vim.cmd 'echohl Question'
  local image_name = vim.fn.input('Image name (without extension): ', '')
  vim.cmd 'echohl None'

  -- If user cancels (empty input), use timestamp as before
  local filename
  if image_name == '' then
    filename = 'image_' .. os.date '%Y%m%d%H%M%S' .. '.png'
  else
    -- Use the provided name
    filename = image_name .. '.png'
  end

  local filepath = img_dir .. '/' .. filename

  -- Try to paste the image
  local result = vim.fn.system('pngpaste "' .. filepath .. '"')
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    print 'Error: No image data in clipboard or pngpaste failed'
    return
  end

  -- Insert markdown image link
  local image_link = '![' .. image_name .. '](images/' .. filename .. ')'
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, cursor_pos[2]) .. image_link .. line:sub(cursor_pos[2] + 1)
  vim.api.nvim_set_current_line(new_line)
end

vim.keymap.set('n', '<leader>pi', paste_image, { buffer = true, desc = '[P]aste clipboard [i]mage' })

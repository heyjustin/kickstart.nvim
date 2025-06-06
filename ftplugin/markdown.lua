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

-- Generate a table of contents
-- Requires the https://github.com/jonschlinkert/markdown-toc plugin

local function update_markdown_toc(heading2)
  local path = vim.fn.expand '%' -- Expands the current file name to a full path
  local bufnr = 0 -- The current buffer number, 0 references the current active buffer
  -- Save the current view
  -- If I don't do this, my folds are lost when I run this keymap
  vim.cmd 'mkview'
  -- Retrieves all lines from the current buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local toc_exists = false -- Flag to check if TOC marker exists
  local frontmatter_end = 0 -- To store the end line number of frontmatter
  -- Check for frontmatter and TOC marker
  for i, line in ipairs(lines) do
    if i == 1 and line:match '^---$' then
      -- Frontmatter start detected, now find the end
      for j = i + 1, #lines do
        if lines[j]:match '^---$' then
          frontmatter_end = j
          break
        end
      end
    end
    -- Checks for the TOC marker
    if line:match '^%s*<!%-%-%s*toc%s*%-%->%s*$' then
      toc_exists = true
      break
    end
  end
  -- Inserts H2 and H3 headings and <!-- toc --> at the appropriate position
  if not toc_exists then
    local insertion_line = 1 -- Default insertion point after first line
    if frontmatter_end > 0 then
      -- Find H1 after frontmatter
      for i = frontmatter_end + 1, #lines do
        if lines[i]:match '^#%s+' then
          insertion_line = i + 1
          break
        end
      end
    else
      -- Find H1 from the beginning
      for i, line in ipairs(lines) do
        if line:match '^#%s+' then
          insertion_line = i + 1
          break
        end
      end
    end
    -- Insert the specified headings and <!-- toc --> without blank lines
    -- Insert the TOC inside a H2 and H3 heading right below the main H1 at the top lamw25wmal
    vim.api.nvim_buf_set_lines(bufnr, insertion_line, insertion_line, false, { heading2, '<!-- toc -->' })
  end
  -- Silently save the file, in case TOC is being created for the first time
  vim.cmd 'silent write'
  -- Silently run markdown-toc to update the TOC without displaying command output
  -- vim.fn.system("markdown-toc -i " .. path)
  -- I want my bulletpoints to be created only as "-" so passing that option as
  -- an argument according to the docs
  -- https://github.com/jonschlinkert/markdown-toc?tab=readme-ov-file#optionsbullets
  vim.fn.system('markdown-toc --bullets "-" -i ' .. path)
  vim.cmd 'edit!' -- Reloads the file to reflect the changes made by markdown-toc
  vim.cmd 'silent write' -- Silently save the file
  vim.notify('TOC updated and file saved', vim.log.levels.INFO)
  -- -- In case a cleanup is needed, leaving this old code here as a reference
  -- -- I used this code before I implemented the frontmatter check
  -- -- Moves the cursor to the top of the file
  -- vim.api.nvim_win_set_cursor(bufnr, { 1, 0 })
  -- -- Deletes leading blank lines from the top of the file
  -- while true do
  --   -- Retrieves the first line of the buffer
  --   local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  --   -- Checks if the line is empty
  --   if line == "" then
  --     -- Deletes the line if it's empty
  --     vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {})
  --   else
  --     -- Breaks the loop if the line is not empty, indicating content or TOC marker
  --     break
  --   end
  -- end
  -- Restore the saved view (including folds)
  vim.cmd 'loadview'
end

vim.keymap.set('n', '<leader>mtt', function()
  update_markdown_toc '## Table of contents'
end, { desc = 'Insert/update Markdown TOC' })

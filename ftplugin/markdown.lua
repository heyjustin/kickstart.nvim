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
    error_message 'Error: No image data in clipboard or pngpaste failed'
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

-- Export to wiki functionality
local function export_to_wiki(opts)
  local function capitalize_and_remove_spaces(str)
    -- Function to capitalize the first letter of a word
    local function capitalizeFirst(word)
      if #word > 0 then
        return word:sub(1, 1):upper() .. word:sub(2)
      else
        return word
      end
    end

    -- Split the string into words, capitalize each word, and concatenate without spaces
    local result = ''
    for word in str:gmatch '%S+' do
      result = result .. capitalizeFirst(word)
    end

    return result
  end

  local debug_mode = (opts ~= nil) and (opts.args == 'debug') or false

  -- Use colored output for progress messages
  local function success_message(msg)
    vim.api.nvim_echo({ { msg, 'String' } }, true, {})
    vim.cmd 'redraw' -- Force immediate display
  end

  local function error_message(msg)
    vim.api.nvim_echo({ { msg, 'ErrorMsg' } }, true, {})
  end

  local function debug_message(msg)
    vim.api.nvim_echo({ { msg, 'Comment' } }, true, {})
    vim.cmd 'redraw' -- Force immediate display
  end

  local function url_message(msg, url)
    vim.api.nvim_echo({ { msg, 'String' }, { url, 'Directory' } }, true, {})
  end

  success_message 'Preparing content for export...'

  local user = os.getenv 'USER'
  local wiki_base_url = os.getenv 'WIKI_BASE_URL'

  -- Get the current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')

  -- Check if the file has frontmatter (starts with ---)
  if not content:match '^%-%-%-\n' then
    error_message "Error: No frontmatter found. The file must start with '---'"
    return
  end

  -- Extract frontmatter
  local frontmatter = content:match '^%-%-%-\n(.-)\n%-%-%-\n'
  if not frontmatter then
    error_message "Error: Invalid frontmatter format. Must be enclosed with '---'"
    return
  end

  -- Parse frontmatter to extract title and wiki-path
  local title, wiki_path
  for line in frontmatter:gmatch '[^\r\n]+' do
    local key, value = line:match '^%s*(%S+):%s*(.+)%s*$'
    if key and value then
      if key == 'title' then
        title = value:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace
      elseif key == 'wiki-path' then
        wiki_path = value:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace
      end
    end
  end

  -- Validate required fields
  if not title then
    error_message "Error: Missing 'title' in frontmatter. Please add a title before exporting."
    return
  end

  if not wiki_path then
    error_message "Error: Missing 'wiki-path' in frontmatter. Please add a wiki-path before exporting."
    return
  end

  -- Strip frontmatter from content
  local document_content = content:gsub('^%-%-%-\n.-\n%-%-%-\n', '')

  -- Create URL-friendly title by removing spaces and capitalizing each word
  local url_title = capitalize_and_remove_spaces(title)

  -- Escape XML special characters in content
  local escaped_content = document_content:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'):gsub("'", '&apos;')

  -- Escape XML special characters in title
  local escaped_title = title:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'):gsub("'", '&apos;')

  -- Create XML payload
  local xml_payload = string.format(
    [[<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<page xmlns="http://www.xwiki.org">
  <comment>Exported from Neovim</comment>
  <content>%s</content>
  <syntax>markdown/1.2</syntax>
  <title>%s</title>
</page>]],
    escaped_content,
    escaped_title
  )

  -- Construct the wiki path
  local wiki_spaces = ''
  for part in wiki_path:gmatch '[^/]+' do
    wiki_spaces = wiki_spaces .. '/spaces/' .. part
  end

  -- Construct the endpoint URL
  local endpoint = string.format('%/rest/wikis/xwiki/spaces/Users/spaces/%s%s/spaces/%s/pages/WebHome', wiki_base_url, user, wiki_spaces, url_title)

  -- STEP 1: First make a GET request to establish authentication context
  success_message 'Authenticating with wiki...'
  local get_command = string.format([[curl -L --cookie ~/.midway/cookie --cookie-jar ~/.midway/cookie -X GET "%s"]], endpoint)

  -- Execute the GET request
  local get_temp_file = os.tmpname()
  local get_cmd_file = io.open(get_temp_file, 'w')
  get_cmd_file:write(get_command)
  get_cmd_file:close()

  local get_output_file = os.tmpname()
  os.execute('bash ' .. get_temp_file .. ' > ' .. get_output_file .. ' 2>&1')

  -- STEP 2: Then make the PUT request with the XML payload
  success_message 'Uploading content to wiki...'
  local put_command = string.format(
    [[curl -L --cookie ~/.midway/cookie --cookie-jar ~/.midway/cookie -X PUT -H "Content-Type: application/xml" -d '%s' "%s"]],
    xml_payload:gsub("'", "'\\''"), -- Escape single quotes for shell
    endpoint
  )

  -- Execute the PUT request
  local put_temp_file = os.tmpname()
  local put_cmd_file = io.open(put_temp_file, 'w')
  put_cmd_file:write(put_command)
  put_cmd_file:close()

  local put_output_file = os.tmpname()
  os.execute('bash ' .. put_temp_file .. ' > ' .. put_output_file .. ' 2>&1')

  -- Read and display output from PUT request
  local result_file = io.open(put_output_file, 'r')
  local result = result_file:read '*all'
  result_file:close()

  -- Clean up temporary files
  os.remove(get_temp_file)
  os.remove(get_output_file)
  os.remove(put_temp_file)
  os.remove(put_output_file)

  -- Show result
  url_message('Export complete.  Wiki URL: ' .. wiki_base_url .. '/bin/view/Users/' .. user .. '/' .. wiki_path .. '/' .. url_title)

  -- Show commands for debugging
  if debug_mode then
    -- Show commands for debugging
    debug_message '\nExecuted commands:'
    debug_message('1. GET: ' .. get_command)
    debug_message('2. PUT: ' .. put_command)

    -- Show response
    if #result > 0 then
      debug_message '\nResponse:'
      debug_message(result)
    end
  end
end

-- Register the command
vim.api.nvim_create_user_command('MarkdownWikiExport', export_to_wiki, {
  nargs = '?', -- Accept 0 or 1 argument
  desc = 'Export current markdown file to wiki (use "debug" for verbose output)',
})

vim.keymap.set('n', '<leader>mwe', export_to_wiki, { desc = '[m]arkdown [w]iki [e]xport' })

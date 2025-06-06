return {
  'jonschlinkert/markdown-toc',
  ft = 'markdown',
  build = function()
    -- Check if markdown-toc is already installed globally
    local is_installed = (vim.fn.system('npm list -g markdown-toc'):find 'markdown%-toc@' ~= nil)

    if not is_installed then
      print 'Installing markdown-toc globally...'
      vim.fn.system 'npm install -g markdown-toc'
      print 'markdown-toc installed globally'
    else
      print 'markdown-toc is already installed globally'
    end
  end,
  config = function() end,
}

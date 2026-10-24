-- Options are automatically loaded before lazy.nvim startup.
if not vim.g.vscode then
  require("config.remote_clipboard").setup()
end

vim.opt.relativenumber = false
vim.g.autoformat = false

-- Keep LSP errors without allowing the log to grow indefinitely.
require("config.lsp_log").setup()

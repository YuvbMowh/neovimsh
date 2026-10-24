-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Restore Chinese input in Insert mode; normal-mode keys remain Latin.
-- Do not install this policy in standalone Neovim.
if vim.g.vscode and vim.fn.executable("fcitx5-remote") == 1 then
  local restore_ime = false
  local group = vim.api.nvim_create_augroup("vscode_fcitx", { clear = true })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      local result = vim.fn.system({ "fcitx5-remote" })
      restore_ime = vim.v.shell_error == 0 and result:match("2") ~= nil
      if restore_ime then vim.fn.jobstart({ "fcitx5-remote", "-c" }) end
    end,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      if restore_ime then vim.fn.jobstart({ "fcitx5-remote", "-o" }) end
    end,
  })
end

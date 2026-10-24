local M = {}
local timer
local limit = 5 * 1024 * 1024

-- Copy then truncate: existing Neovim processes can keep their log handles.
function M.rotate()
  local path = vim.fn.stdpath("log") .. "/lsp.log"
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.size <= limit then
    return
  end
  if not vim.uv.fs_copyfile(path, path .. ".1") then
    return
  end
  local file = io.open(path, "w")
  if file then
    file:close()
  end
end

function M.setup()
  vim.lsp.log.set_level("warn")
  M.rotate()
  if timer then
    return
  end
  timer = assert(vim.uv.new_timer())
  timer:start(60000, 60000, vim.schedule_wrap(M.rotate))
  timer:unref()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      timer:stop()
      timer:close()
      M.rotate()
    end,
  })
end

return M

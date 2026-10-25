-- Loaded by install.sh after normal configuration startup.
local function check_tasks(require_installed)
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    for _, task in ipairs(plugin._.tasks or {}) do
      assert(not task:has_errors(), name .. ": " .. (task:output() or "plugin task failed"))
    end
    if require_installed and plugin.url then
      assert(plugin._.installed, name .. ": plugin is not installed")
    end
  end
  assert(vim.v.errmsg == "", vim.v.errmsg)
end

local ok, err = xpcall(function()
  local lazy = require("lazy")
  check_tasks(false)
  lazy.install({ wait = true, show = false, lockfile = true })
  check_tasks(true)
  lazy.restore({ wait = true, show = false })
  check_tasks(true)
end, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
vim.cmd("qa")

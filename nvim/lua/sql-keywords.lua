local M = {}

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return vim.tbl_contains({ "sql", "mysql", "plsql" }, vim.bo.filetype)
end

function M:get_completions(_, callback)
  local items = vim.tbl_map(function(word)
    return { label = word, kind = vim.lsp.protocol.CompletionItemKind.Keyword }
  end, vim.fn["vim_dadbod_completion#reserved_keywords#get"]())
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

return M

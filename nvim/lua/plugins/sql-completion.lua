return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          sql = { "sql_keywords", inherit_defaults = true },
          mysql = { "sql_keywords", inherit_defaults = true },
          plsql = { "sql_keywords", inherit_defaults = true },
        },
        providers = {
          sql_keywords = { name = "SQL", module = "sql-keywords" },
        },
      },
    },
  },
}

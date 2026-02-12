return {
  "mfussenegger/nvim-lint",
  cond = not vim.g.lightweight,
  opts = {
    linters_by_ft = {
      markdown = {}, -- No linters for markdown
    },
  },
}

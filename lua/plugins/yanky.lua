return {
  "gbprod/yanky.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    ring = {
      history_length = 5, -- Keep only last 5 yanks
      storage = "memory", -- Don't persist to disk (lighter)
    },
  },
  keys = {
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" } },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },
    { "<c-p>", "<Plug>(YankyPreviousEntry)", desc = "Previous yank" },
    { "<c-n>", "<Plug>(YankyNextEntry)", desc = "Next yank" },
    { "<leader>sy", "<cmd>Telescope yank_history<cr>", desc = "Yank History" },
  },
}

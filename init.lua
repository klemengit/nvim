-- Lightweight mode: NVIM_LIGHT=1 nvim file.txt
vim.g.lightweight = vim.env.NVIM_LIGHT == "1"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

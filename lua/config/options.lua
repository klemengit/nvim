-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable smooth scrolling (causes laggy Ctrl+d/Ctrl+u)
vim.g.snacks_animate = false

-- Disable autoformat on save by default
vim.g.autoformat = false

-- Fixed Neovim server socket (works across sessions)
local sock = vim.fn.stdpath("run") .. "/nvim.sock" -- usually ~/.local/state/nvim/nvim.sock
vim.g.nvim_listen_address = sock
if vim.fn.exists("*serverstart") == 1 then
  pcall(vim.fn.serverstart, sock) -- harmless if already running
end
vim.env.NVIM_LISTEN_ADDRESS = sock

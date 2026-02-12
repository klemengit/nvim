-- Disabled LazyVim bundled plugins.
-- Re-enable any of these by removing the corresponding line.
return {
  -- Auto-closes brackets, quotes, and parentheses as you type
  -- { "nvim-mini/mini.pairs", enabled = false },
  -- Improved multi-language comment syntax (e.g. JSX, Vue, TS)
  -- { "folke/ts-comments.nvim", enabled = false },
  -- LuaLS auto-completion and type checking for Neovim config files
  -- { "folke/lazydev.nvim", enabled = false },
  -- Multi-file search and replace UI (<leader>sr)
  -- { "MagicDuck/grug-far.nvim", enabled = false },
  -- Enhanced jump/motion with labels shown at match locations (s/S)
  { "folke/flash.nvim", enabled = false },
  -- Popup showing available keybindings as you type (<leader>?)
  -- { "folke/which-key.nvim", enabled = false },
  -- Git change indicators in sign column, hunk staging/navigation
  -- { "lewis6991/gitsigns.nvim", enabled = false },
  -- Pretty list for diagnostics, references, quickfix (<leader>xx)
  -- {"folke/trouble.nvim", enabled = false },
  -- Highlights and lists TODO/HACK/BUG/FIX comments in the project
  -- { "folke/todo-comments.nvim", enabled = false },
  -- Fancy tab bar with icons, pinning, and close buttons
  -- { "akinsho/bufferline.nvim", enabled = false },
  -- Statusline with mode, branch, diagnostics, file path, clock
  -- { "nvim-lualine/lualine.nvim", enabled = false },
  -- Replaces cmdline, messages, and popupmenu with a modern UI
  -- { "folke/noice.nvim", enabled = false },
  -- UI component library (dependency of noice)
  -- { "MunifTanjim/nui.nvim", enabled = false },
  -- Treesitter-based text objects and motions (]f ]c ]a for function/class/arg)
  -- { "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },
  -- Auto-closes and auto-renames HTML/JSX tags
  -- { "windwp/nvim-ts-autotag", enabled = false },
  -- Catppuccin colorscheme (not in use, tokyonight is active)
  { "catppuccin/nvim", enabled = false },
  -- Mason-LSP bridge (disabled in lightweight mode along with LSP/mason)
  { "mason-org/mason-lspconfig.nvim", cond = not vim.g.lightweight },
}

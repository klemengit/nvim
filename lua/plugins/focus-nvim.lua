return {
  "nvim-focus/focus.nvim",
  version = false,
  event = "VeryLazy", -- Load after LazyVim initialization
  config = function()
    require("focus").setup({
      enable = true,
      commands = true,
      autoresize = {
        enable = false,
      },
      split = {
        bufnew = false,
        tmux = false,
      },
    })

    --  Auto-enable after LazyVim fully loads
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        vim.defer_fn(function()
          require("focus").focus_enable()
        end, 500) -- Delay to ensure LazyVim theme is loaded
      end,
    })

    -- Enhance the highlight difference
    vim.api.nvim_set_hl(0, "Normal", { -- "NormalNC" is for inactive window
      bg = "#1a1c2a", -- Darker for active
    })
  end,
  keys = {
    { "<leader>tf", "<cmd>FocusToggle<cr>", desc = "Toggle Focus" },
  },
}

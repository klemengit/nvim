-- Markdown Preview Configuration for Neovim
-- Place this file in ~/.config/nvim/lua/ or source it from your init.lua

return {
  -- Using markdown-preview.nvim plugin
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    config = function()
      -- Plugin settings
      vim.g.mkdp_auto_start = 0 -- Don't auto-open preview
      vim.g.mkdp_auto_close = 0 -- don't Auto-close preview when changing buffer
      vim.g.mkdp_refresh_slow = 0 -- Refresh on save or leaving insert mode
      vim.g.mkdp_command_for_global = 0 -- Only available for markdown files
      vim.g.mkdp_open_to_the_world = 0 -- Only accessible from localhost
      vim.g.mkdp_browser = "" -- Use default browser
      vim.g.mkdp_echo_preview_url = 1 -- Echo preview URL in command line
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {}
      }

      -- Keybindings for Markdown preview
      -- These only apply to markdown files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          local opts = { buffer = true, silent = true }
          
          -- Toggle preview
          vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", 
            vim.tbl_extend("force", opts, { desc = "Toggle Markdown Preview" }))
          
        end,
      })
    end,
  },
}

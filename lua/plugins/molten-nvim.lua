-- return {
--   {
--     "benlubas/molten-nvim",
--     version = "^1.0.0",
--     dependencies = { "3rd/image.nvim" },
--     build = ":UpdateRemotePlugins",
--     init = function()
--       vim.g.molten_image_provider = "image.nvim"
--       vim.g.molten_output_win_max_height = 20
--       vim.g.molten_virt_text_output = true
--       vim.g.molten_virt_lines_off_by_1 = true
--
--       -- Set cell separator for Python files
--       vim.g.molten_cell_separator = "# %%"
--     end,
--
--     config = function()
--       -- Set up keymap for running cell using MoltenEvaluateOperator with ic text object
--       vim.keymap.set("n", "<leader>mr", function()
--         vim.cmd("normal! \\<Cmd>MoltenEvaluateOperator\\<CR>ic")
--       end, { desc = "Run cell" })
--     end,
--
--     keys = {
--       { "<leader>mi", ":MoltenInit<CR>", desc = "Initialize Molten" },
--       { "<leader>mx", ":MoltenDeinit<CR>", desc = "De-initialize Molten" },
--       { "<leader>me", ":MoltenEvaluateOperator<CR>", desc = "Evaluate operator", mode = "n" },
--       { "<leader>ml", ":MoltenEvaluateLine<CR>", desc = "Evaluate line" },
--       { "<leader>mc", ":MoltenReevaluateCell<CR>", desc = "Re-evaluate cell" },
--       { "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>", desc = "Evaluate visual", mode = "v" },
--     },
--   },
-- }

return {
  -- Molten for Jupyter kernel interaction
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_output_win_max_height = 50
      vim.g.molten_virt_text_max_lines = 20
      vim.g.molten_auto_open_output = true
      -- Auto-detect terminal and set image provider accordingly
      if vim.env.TERM == "xterm-kitty" or vim.env.TERM_PROGRAM == "WezTerm" then
        vim.g.molten_image_provider = "image.nvim"
      else
        vim.g.molten_image_provider = "none"
      end
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_enter_output_behavior = "open_and_enter"
    end,
  },

  -- NotebookNavigator for simple cell detection and execution
  {
    "GCBallesteros/NotebookNavigator.nvim",
    keys = {
      { "<leader>mj", function() require("notebook-navigator").move_cell("d") end, desc = "Next cell" },
      { "<leader>mk", function() require("notebook-navigator").move_cell("u") end, desc = "Previous cell" },
      { "<leader>md", function() require("notebook-navigator").add_cell_below() end, desc = "Add cell bellow" },
      { "<leader>mc", "<cmd>lua require('notebook-navigator').run_and_move()<cr>", desc = "Run cell and move" },
      { "<leader>mC", "<cmd>lua require('notebook-navigator').run_cell()<cr>", desc = "Run cell" },
      { 
        "<leader>ma", 
        function()
          -- Save cursor position (line number)
          local target_line = vim.api.nvim_win_get_cursor(0)[1]
          
          -- Go to top of file
          vim.cmd("normal! gg")
          
          -- Run cells until we reach the target
          while true do
            -- Run current cell and move to next
            require('notebook-navigator').run_and_move()
            vim.cmd("sleep 100m")

            local current_line = vim.api.nvim_win_get_cursor(0)[1]
            
            -- If we've passed the target cell, we're done
            if current_line >= target_line then
              break
            end
          end
          
          -- Restore cursor position
          vim.api.nvim_win_set_cursor(0, {target_line, 0})
        end,
        desc = "Run all cells above (including current)" 
      },
      { "<leader>mi", ":MoltenInit<CR>", desc = "Initialize molten" },
      { "<leader>mx", ":MoltenDeinit<CR>", desc = "Deinitialize molten" },
      { "<leader>mo", ":MoltenShowOutput<CR>", desc = "Show output window" },
      { "<leader>mh", ":MoltenHideOutput<CR>", desc = "Hide output window" },
      { "<localleader>mr", ":MoltenRestart<CR>", desc = "Restart Kernel" },
      { "<localleader>mi", ":MoltenInterrupt<CR>", desc = "Interrup kernel" },
      { "<leader>mb", ":MoltenOpenInBrowser<CR>", desc = "Open output in browser" },
      vim.keymap.set("n", "<leader>me", ":noautocmd MoltenEnterOutput<CR>",
          { silent = true, desc = "show/enter output" }),
    },
    dependencies = {
      "benlubas/molten-nvim",
    },
    opts = {
      cell_markers = {
        python = "# %%",
      },
      repl_provider = "molten",
      syntax_highlight = true,
    },
  },

  -- image.nvim for inline image rendering (only loads in compatible terminals)
  {
    "3rd/image.nvim",
    enabled = function()
      return vim.env.TERM == "xterm-kitty" or vim.env.TERM_PROGRAM == "WezTerm"
    end,
    opts = {
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
        },
      },
      max_width = 100,
      max_height = 100,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },

  -- Jupytext for .ipynb <-> .py conversion
  {
    "GCBallesteros/jupytext.nvim",
    opts = {
      style = "percent",
      output_extension = "auto",
      force_ft = nil,
    },
    lazy = false,
  },
}

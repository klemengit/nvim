-- Simplified Jupyter-like setup using only toggleterm
-- Place in ~/.config/nvim/lua/plugins/jupyter-simple.lua

return {
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
          return 15
        end,
        open_mapping = [[<C-\>]],
        direction = "vertical",
        close_on_exit = false,
        start_in_insert = false,
      })

      local Terminal = require("toggleterm.terminal").Terminal
      local python_repl = Terminal:new({
        cmd = "python3",
        dir = "git_dir",
        direction = "vertical",
        count = 2,
      })

      -- Custom functions for Jupyter-like workflow
      local function setup_jupyter_keymaps()
        local map = vim.keymap.set

        -- Cell selection function
        local function select_cell()
          local current_line = vim.fn.line(".")
          local total_lines = vim.fn.line("$")

          -- Find start of current cell
          local cell_start = current_line
          for i = current_line, 1, -1 do
            local line = vim.fn.getline(i)
            if line:match("^%s*#%s*%%%%") then
              cell_start = i + 1
              break
            elseif i == 1 then
              cell_start = 1
              break
            end
          end

          -- Find end of current cell
          local cell_end = total_lines
          for i = current_line + 1, total_lines do
            local line = vim.fn.getline(i)
            if line:match("^%s*#%s*%%%%") then
              cell_end = i - 1
              break
            end
          end

          -- Skip empty lines
          while cell_start <= cell_end and vim.fn.getline(cell_start):match("^%s*$") do
            cell_start = cell_start + 1
          end
          while cell_end >= cell_start and vim.fn.getline(cell_end):match("^%s*$") do
            cell_end = cell_end - 1
          end

          return cell_start, cell_end
        end

        -- Send text to Python REPL
        local function send_to_repl(text)
          if not python_repl:is_open() then
            python_repl:open()
            -- Wait for terminal to be ready
            vim.defer_fn(function()
              python_repl:send(text, false)
              vim.cmd("wincmd p") -- Return focus to code
            end, 500)
          else
            python_repl:send(text, false)
            vim.cmd("wincmd p") -- Return focus to code immediately
          end
        end

        -- Start/toggle Python REPL
        local function toggle_jupyter_repl()
          python_repl:toggle()
          if python_repl:is_open() then
            -- Load common imports when first opened
            vim.defer_fn(function()
              -- python_repl:send("import numpy as np", false)
              -- python_repl:send("import pandas as pd", false)
              -- python_repl:send("import matplotlib.pyplot as plt", false)
              vim.cmd("wincmd p") -- Return focus to code
            end, 1000)
          end
        end

        -- Run current cell
        local function run_cell()
          local cell_start, cell_end = select_cell()
          if cell_start <= cell_end then
            local lines = vim.api.nvim_buf_get_lines(0, cell_start - 1, cell_end, false)
            local code = table.concat(lines, "\n")
            send_to_repl(code)

            -- Move to next cell
            local current_line = vim.fn.line(".")
            for i = current_line + 1, vim.fn.line("$") do
              local line = vim.fn.getline(i)
              if line:match("^%s*#%s*%%%%") then
                vim.fn.cursor(i + 1, 1)
                break
              end
            end
          end
        end

        -- Run all cells above current position
        local function run_cells_above()
          local current_line = vim.fn.line(".")
          local cells = {}

          -- Find all cell boundaries from start to current position
          local cell_starts = { 1 } -- First cell starts at line 1

          for i = 1, current_line do
            local line = vim.fn.getline(i)
            if line:match("^%s*#%s*%%%%") then
              table.insert(cell_starts, i + 1)
            end
          end

          -- Extract code from each cell above current position
          for i = 1, #cell_starts - 1 do
            local cell_start = cell_starts[i]
            local cell_end = cell_starts[i + 1] - 2 -- End before next cell marker

            -- Skip empty lines at start and end
            while cell_start <= cell_end and vim.fn.getline(cell_start):match("^%s*$") do
              cell_start = cell_start + 1
            end
            while cell_end >= cell_start and vim.fn.getline(cell_end):match("^%s*$") do
              cell_end = cell_end - 1
            end

            if cell_start <= cell_end then
              local lines = vim.api.nvim_buf_get_lines(0, cell_start - 1, cell_end, false)
              local code = table.concat(lines, "\n")
              if code:match("%S") then -- Only add non-empty cells
                table.insert(cells, code)
              end
            end
          end

          -- Run all cells
          if #cells > 0 then
            vim.notify("Running " .. #cells .. " cells above...")
            for i, code in ipairs(cells) do
              send_to_repl(code)
            end
            vim.notify("✓ Executed " .. #cells .. " cells above")
          else
            vim.notify("No cells found above current position")
          end
        end

        -- Run selection or current line
        local function run_selection()
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" or mode == "\22" then
            -- Visual mode - get selection
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")
            local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

            if #lines == 1 then
              -- Single line - handle column selection
              lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
            elseif #lines > 1 then
              -- Multiple lines
              lines[1] = string.sub(lines[1], start_pos[3])
              lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
            end

            local code = table.concat(lines, "\n")
            send_to_repl(code)
          else
            -- Normal mode - send current line
            local line = vim.fn.getline(".")
            send_to_repl(line)
          end
        end

        -- Navigation functions
        local function next_cell()
          local current_line = vim.fn.line(".")
          for i = current_line + 1, vim.fn.line("$") do
            if vim.fn.getline(i):match("^%s*#%s*%%%%") then
              vim.fn.cursor(i + 1, 1)
              return
            end
          end
        end

        local function prev_cell()
          local current_line = vim.fn.line(".")
          for i = current_line - 1, 1, -1 do
            if vim.fn.getline(i):match("^%s*#%s*%%%%") then
              vim.fn.cursor(i + 1, 1)
              return
            end
          end
          vim.fn.cursor(1, 1)
        end

        -- Create new cell
        local function create_cell_below()
          vim.cmd("normal! o")
          vim.fn.setline(".", "# %%")
          vim.cmd("normal! o")
          vim.cmd("startinsert")
        end

        -- Modified toggle that preserves REPL state
        local function smart_toggle_repl()
          if python_repl:is_open() then
            python_repl:close() -- This hides rather than kills the process
          else
            python_repl:open()
          end
        end

        -- Key mappings
        map("n", "<leader>jr", toggle_jupyter_repl, { desc = "Toggle Jupyter REPL" })
        map("n", "<leader>jc", run_cell, { desc = "Run current cell" })
        map("n", "<leader>jl", run_selection, { desc = "Run current line" })
        map("v", "<leader>jl", run_selection, { desc = "Run selection" })
        map("n", "<leader>jn", create_cell_below, { desc = "Create cell below" })
        map("n", "<leader>ja", run_cells_above, { desc = "Run all cells above" })
        map("n", "<leader>jt", smart_toggle_repl, { desc = "Toggle REPL visibility" })

        -- Navigation
        map("n", "]]", next_cell, { desc = "Next cell" })
        map("n", "[[", prev_cell, { desc = "Previous cell" })

        -- Cell text object
        map("o", "ic", function()
          local cell_start, cell_end = select_cell()
          vim.fn.cursor(cell_start, 1)
          vim.cmd("normal! V")
          vim.fn.cursor(cell_end, vim.fn.col({ cell_end, "$" }))
        end, { desc = "Select cell content" })

        map("n", "vic", function()
          local cell_start, cell_end = select_cell()
          vim.fn.cursor(cell_start, 1)
          vim.cmd("normal! V")
          vim.fn.cursor(cell_end, vim.fn.col({ cell_end, "$" }))
        end, { desc = "Select cell" })

        -- Quick commands
        map("n", "<leader>ji", function()
          send_to_repl("plt.show()")
        end, { desc = "Show plots" })

        map("n", "<leader>jx", function()
          send_to_repl("exit()")
        end, { desc = "Exit REPL" })

        -- Notebook conversion commands
        map("n", "<leader>jw", function()
          local current_file = vim.fn.expand("%:p")
          if current_file:match("%.py$") then
            local ipynb_file = current_file:gsub("%.py$", ".ipynb")
            vim.fn.system("jupytext --to ipynb --output " .. ipynb_file .. " " .. current_file)
            if vim.v.shell_error == 0 then
              vim.notify("Converted to " .. vim.fn.fnamemodify(ipynb_file, ":t"))
            else
              vim.notify("Conversion failed. Is jupytext installed?", vim.log.levels.ERROR)
            end
          end
        end, { desc = "Write to .ipynb" })
      end

      -- Auto-setup for Python files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = setup_jupyter_keymaps,
      })
    end,
  },
}

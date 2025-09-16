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
        cmd = "ipython --no-banner --automagic --colors=Linux",
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

        -- Enhanced send_to_repl with IPython support and indentation handling
        local function send_to_repl(text, ensure_ready)
          -- Clean up text and ensure proper block completion for IPython
          local lines = vim.split(text, "\n")
          local processed_lines = {}
          local has_indented_content = false

          -- Process each line
          for _, line in ipairs(lines) do
            table.insert(processed_lines, line)
            if line:match("^%s+%S") then -- Line starts with whitespace and has content
              has_indented_content = true
            end
          end

          local processed_text = table.concat(processed_lines, "\n")

          -- Add extra newline for indented blocks to ensure execution
          if has_indented_content then
            processed_text = processed_text .. "\n"
          end

          if not python_repl:is_open() then
            python_repl:open()
            if ensure_ready then
              -- Wait for IPython to fully initialize
              vim.defer_fn(function()
                -- Load common imports with IPython magic
                python_repl:send("import numpy as np", false)
                python_repl:send("import pandas as pd", false)
                python_repl:send("import matplotlib.pyplot as plt", false)
                python_repl:send("%matplotlib inline", false) -- Enable inline plots
                vim.defer_fn(function()
                  python_repl:send(processed_text, false)
                  vim.cmd("wincmd p")
                end, 500)
              end, 1000)
            else
              -- Quick initialization for single commands
              vim.defer_fn(function()
                python_repl:send(processed_text, false)
                vim.cmd("wincmd p")
              end, 500)
            end
          else
            python_repl:send(processed_text, false)
            vim.cmd("wincmd p")
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
            local combined_code = table.concat(cells, "\n\n")
            send_to_repl(combined_code, true) -- Use ensure_ready=true
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
          local cell_markers = {}

          -- Collect all cell marker positions
          for i = 1, vim.fn.line("$") do
            if vim.fn.getline(i):match("^%s*#%s*%%%%") then
              table.insert(cell_markers, i)
            end
          end

          -- Find current cell and go to previous one
          for i = #cell_markers, 1, -1 do
            if cell_markers[i] < current_line then
              vim.fn.cursor(cell_markers[i] + 1, 1)
              return
            end
          end

          -- No previous cell found, go to beginning
          vim.fn.cursor(1, 1)
          vim.notify("At first cell")
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

        -- Convert .ipynb to .py file
        map("n", "<leader>jp", function()
          local current_file = vim.fn.expand("%:p")
          if current_file:match("%.ipynb$") then
            local py_file = current_file:gsub("%.ipynb$", ".py")
            -- Use jupytext to convert with cell markers
            local cmd = "jupytext --to py:percent --output "
              .. vim.fn.shellescape(py_file)
              .. " "
              .. vim.fn.shellescape(current_file)
            local result = vim.fn.system(cmd)

            if vim.v.shell_error == 0 then
              vim.notify("Converted to " .. vim.fn.fnamemodify(py_file, ":t"))
              -- Optionally open the converted file
              vim.cmd("edit " .. py_file)
            else
              vim.notify("Conversion failed: " .. result, vim.log.levels.ERROR)
              vim.notify("Is jupytext installed? Try: pip install jupytext", vim.log.levels.INFO)
            end
          else
            vim.notify("Not a .ipynb file", vim.log.levels.WARN)
          end
        end, { desc = "Convert .ipynb to .py" })

        -- Run all cells in file
        local function run_all_cells()
          local total_lines = vim.fn.line("$")
          local cells = {}
          local cell_starts = { 1 } -- First cell starts at line 1

          -- Find all cell boundaries in the entire file
          for i = 1, total_lines do
            local line = vim.fn.getline(i)
            if line:match("^%s*#%s*%%%%") then
              table.insert(cell_starts, i + 1)
            end
          end

          -- Extract code from each cell
          for i = 1, #cell_starts do
            local cell_start = cell_starts[i]
            local cell_end

            if i < #cell_starts then
              cell_end = cell_starts[i + 1] - 2 -- End before next cell marker
            else
              cell_end = total_lines -- Last cell goes to end of file
            end

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
            vim.notify("Running " .. #cells .. " cells in file...")
            local combined_code = table.concat(cells, "\n\n")
            send_to_repl(combined_code, true) -- Use ensure_ready=true
            vim.notify("✓ Executed " .. #cells .. " cells")
          else
            vim.notify("No cells found in file")
          end
        end

        -- Key mappings
        map("n", "<leader>jc", run_cell, { desc = "Run current cell" })
        map("n", "<leader>jl", run_selection, { desc = "Run current line" })
        map("v", "<leader>jl", run_selection, { desc = "Run selection" })
        map("n", "<leader>jn", create_cell_below, { desc = "Create cell below" })
        map("n", "<leader>ja", run_cells_above, { desc = "Run all cells above" })
        map("n", "<leader>jt", smart_toggle_repl, { desc = "Toggle REPL visibility" })
        map("n", "<leader>jf", run_all_cells, { desc = "Run all cells in file" })

        -- Navigation
        map("n", "<leader>jj", next_cell, { desc = "Next cell" })
        map("n", "<leader>jk", prev_cell, { desc = "Previous cell" })

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

        -- Properly exit and destroy REPL
        map("n", "<leader>jx", function()
          if python_repl:is_open() then
            python_repl:shutdown() -- Kill process and close window
            -- Create fresh terminal instance
            python_repl = Terminal:new({
              cmd = "ipython --no-banner --automagic --colors=Linux",
              dir = "git_dir",
              direction = "vertical",
              count = 2,
            })

            vim.notify("REPL terminated")
          else
            vim.notify("No REPL running")
          end
        end, { desc = "Exit and destroy REPL" })

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
      -- vim.api.nvim_create_autocmd("FileType", {
      --   pattern = "python",
      --   callback = setup_jupyter_keymaps,
      -- })
      -- Auto-setup for Python and Jupyter files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = setup_jupyter_keymaps,
      })

      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.ipynb",
        callback = setup_jupyter_keymaps,
      })
    end,
  },
}

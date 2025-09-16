-- Jupyter-like workflow using toggleterm + IPython (robust block sending)
-- Drop-in replacement with fixes for duplicated prompts & raw bracketed markers.

return {
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "vertical" then
            return math.floor(vim.o.columns * 0.4)
          end
          return 15
        end,
        open_mapping = [[<C-\>]],
        direction = "vertical",
        close_on_exit = false,
        start_in_insert = false,
      })

      local Terminal = require("toggleterm.terminal").Terminal

      -- Config: force cpaste if your terminal doesn't support bracketed paste
      vim.g.jupyter_use_cpaste = vim.g.jupyter_use_cpaste or false

      -- One place for the cell marker
      local CELL_MARK = "^%s*#%s*%%%%"

      -- Build IPython command (customize if you want venv detection)
      local function ipython_cmd()
        return "ipython --no-banner --automagic --colors=Linux"
        -- Or auto-activate venv (login shell):
        -- return [[bash -lc 'if [ -n "$VIRTUAL_ENV" ]; then source "$VIRTUAL_ENV/bin/activate"; fi; ipython --no-banner --automagic --colors=Linux']]
      end

      -- Single REPL instance we keep alive between opens/closes
      local python_repl = Terminal:new({
        cmd = ipython_cmd(),
        dir = "git_dir",
        direction = "vertical",
        count = 2,
      })

      -- Track whether we've run our one-time init in this process
      local repl_ready = false

      -- Ensure REPL open + initialized exactly once per process
      local function ensure_repl_ready()
        if not python_repl:is_open() then
          python_repl:open()
        end
        if not repl_ready then
          -- Send init PLAIN (no bracketed paste) to avoid raw markers on first send
          local init_cmds = table.concat({
            -- "import sys, os",
            -- "import numpy as np",
            -- "import pandas as pd",
            -- "import matplotlib.pyplot as plt",
            "",
          }, "\n")
          python_repl:send(init_cmds .. "\n", false)
          repl_ready = true
        end
      end

      -- Helpers
      local function rstrip_newlines(s)
        return (s:gsub("\n+$", "")) -- drop all trailing newlines
      end

      -- Robust sender: bracketed paste (best) or %cpaste fallback
      local function send_to_repl(text, opts)
        opts = opts or {}
        local use_cpaste = opts.cpaste or vim.g.jupyter_use_cpaste

        ensure_repl_ready()

        -- Strip trailing newlines to avoid creating an extra empty cell
        text = rstrip_newlines(text)

        if not use_cpaste then
          -- Bracketed paste: one atomic block + exactly one Enter outside the paste
          local START, END = "\x1b[200~", "\x1b[201~"
          python_repl:send(START .. text .. END .. "\n", false)
        else
          -- cpaste mode: send text and terminate with `--`
          python_repl:send("%cpaste -q\n", false)
          python_repl:send(text .. "\n", false)
          python_repl:send("--\n", false)
        end

        -- Return focus to previous window
        vim.cmd("wincmd p")
      end

      -- Expose a simple toggle to switch paste mode at runtime
      vim.api.nvim_create_user_command("JupyterPasteMode", function()
        vim.g.jupyter_use_cpaste = not vim.g.jupyter_use_cpaste
        vim.notify(
          "Jupyter paste mode: " .. (vim.g.jupyter_use_cpaste and "%cpaste" or "bracketed"),
          vim.log.levels.INFO
        )
      end, { desc = "Toggle between bracketed paste and %cpaste" })

      -- -----------------------
      -- UI Helpers & Navigation
      -- -----------------------

      local function is_cell_marker(line)
        return line:match(CELL_MARK) ~= nil
      end

      local function select_cell()
        local cur = vim.fn.line(".")
        local last = vim.fn.line("$")

        -- find cell start
        local s = cur
        for i = cur, 1, -1 do
          if is_cell_marker(vim.fn.getline(i)) then
            s = i + 1
            break
          elseif i == 1 then
            s = 1
            break
          end
        end

        -- find cell end
        local e = last
        for i = cur + 1, last do
          if is_cell_marker(vim.fn.getline(i)) then
            e = i - 1
            break
          end
        end

        -- trim empties
        while s <= e and vim.fn.getline(s):match("^%s*$") do
          s = s + 1
        end
        while e >= s and vim.fn.getline(e):match("^%s*$") do
          e = e - 1
        end

        return s, e
      end

      local function next_cell()
        local cur = vim.fn.line(".")
        local last = vim.fn.line("$")
        for i = cur + 1, last do
          if is_cell_marker(vim.fn.getline(i)) then
            vim.fn.cursor(i + 1, 1)
            return
          end
        end
      end

      local function prev_cell()
        local cur = vim.fn.line(".")
        local marks = {}
        local last = vim.fn.line("$")
        for i = 1, last do
          if is_cell_marker(vim.fn.getline(i)) then
            table.insert(marks, i)
          end
        end
        for i = #marks, 1, -1 do
          if marks[i] < cur then
            vim.fn.cursor(marks[i] + 1, 1)
            return
          end
        end
        vim.fn.cursor(1, 1)
        vim.notify("At first cell")
      end

      private_create_cell_below_called = false
      local function create_cell_below()
        vim.cmd("normal! o")
        vim.fn.setline(".", "# %%")
        vim.cmd("normal! o")
        vim.cmd("startinsert")
      end

      local function smart_toggle_repl()
        if python_repl:is_open() then
          python_repl:close() -- hides, keeps process
        else
          python_repl:open()
        end
      end

      -- -------------
      -- Runners
      -- -------------

      local function run_cell()
        local s, e = select_cell()
        if s <= e then
          local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
          local code = table.concat(lines, "\n")
          send_to_repl(code)
          -- move to next
          local cur = vim.fn.line(".")
          local last = vim.fn.line("$")
          for i = cur + 1, last do
            if is_cell_marker(vim.fn.getline(i)) then
              vim.fn.cursor(i + 1, 1)
              break
            end
          end
        end
      end

      local function run_cells_above()
        local cur = vim.fn.line(".")
        local starts = { 1 }
        for i = 1, cur do
          if is_cell_marker(vim.fn.getline(i)) then
            table.insert(starts, i + 1)
          end
        end

        local chunks = {}
        for i = 1, #starts - 1 do
          local s = starts[i]
          local e = starts[i + 1] - 2
          while s <= e and vim.fn.getline(s):match("^%s*$") do
            s = s + 1
          end
          while e >= s and vim.fn.getline(e):match("^%s*$") do
            e = e - 1
          end
          if s <= e then
            local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
            local code = table.concat(lines, "\n")
            if code:match("%S") then
              table.insert(chunks, code)
            end
          end
        end

        if #chunks > 0 then
          vim.notify("Running " .. #chunks .. " cells above...")
          send_to_repl(table.concat(chunks, "\n\n"))
          vim.notify("✓ Executed " .. #chunks .. " cells above")
        else
          vim.notify("No cells found above current position")
        end
      end

      local function run_all_cells()
        local last = vim.fn.line("$")
        local starts = { 1 }
        for i = 1, last do
          if is_cell_marker(vim.fn.getline(i)) then
            table.insert(starts, i + 1)
          end
        end

        local chunks = {}
        for i = 1, #starts do
          local s = starts[i]
          local e = (i < #starts) and (starts[i + 1] - 2) or last
          while s <= e and vim.fn.getline(s):match("^%s*$") do
            s = s + 1
          end
          while e >= s and vim.fn.getline(e):match("^%s*$") do
            e = e - 1
          end
          if s <= e then
            local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
            local code = table.concat(lines, "\n")
            if code:match("%S") then
              table.insert(chunks, code)
            end
          end
        end

        if #chunks > 0 then
          vim.notify("Running " .. #chunks .. " cells in file...")
          send_to_repl(table.concat(chunks, "\n\n"))
          vim.notify("✓ Executed " .. #chunks .. " cells")
        else
          vim.notify("No cells found in file")
        end
      end

      local function run_selection_or_line()
        local mode = vim.fn.mode()
        if mode == "v" or mode == "V" or mode == "\22" then
          local s_pos = vim.fn.getpos("'<")
          local e_pos = vim.fn.getpos("'>")
          local lines = vim.api.nvim_buf_get_lines(0, s_pos[2] - 1, e_pos[2], false)

          if #lines == 1 then
            lines[1] = string.sub(lines[1], s_pos[3], e_pos[3])
          elseif #lines > 1 then
            lines[1] = string.sub(lines[1], s_pos[3])
            lines[#lines] = string.sub(lines[#lines], 1, e_pos[3])
          end

          send_to_repl(table.concat(lines, "\n"))
        else
          send_to_repl(vim.fn.getline("."))
        end
      end

      -- ----------------
      -- Extra utilities
      -- ----------------

      local function setup_jupyter_keymaps()
        local map = vim.keymap.set

        -- Exec
        map("n", "<leader>jc", run_cell, { desc = "Run current cell" })
        map("n", "<leader>jl", run_selection_or_line, { desc = "Run current line" })
        map("v", "<leader>jl", run_selection_or_line, { desc = "Run selection" })
        map("n", "<leader>ja", run_cells_above, { desc = "Run all cells above" })
        map("n", "<leader>jf", run_all_cells, { desc = "Run all cells in file" })

        -- Cells
        map("n", "<leader>jn", create_cell_below, { desc = "Create cell below" })
        map("n", "<leader>jj", next_cell, { desc = "Next cell" })
        map("n", "<leader>jk", prev_cell, { desc = "Previous cell" })

        -- REPL visibility & lifecycle
        map("n", "<leader>jt", smart_toggle_repl, { desc = "Toggle REPL visibility" })
        map("n", "<leader>jR", function()
          ensure_repl_ready()
          python_repl:send("%reset -f\n", false)
        end, { desc = "IPython reset (keep session)" })

        map("n", "<leader>jx", function()
          if python_repl:is_open() then
            python_repl:shutdown()
            python_repl = Terminal:new({
              cmd = ipython_cmd(),
              dir = "git_dir",
              direction = "vertical",
              count = 2,
            })
            repl_ready = false
            vim.notify("REPL terminated")
          else
            vim.notify("No REPL running")
          end
        end, { desc = "Exit and destroy REPL" })

        -- Quick helpers
        map("n", "<leader>ji", function()
          send_to_repl("plt.show()")
        end, { desc = "Show plots" })

        -- Text object for a cell (inner cell)
        map("o", "ic", function()
          local s, e = select_cell()
          vim.fn.cursor(s, 1)
          vim.cmd("normal! V")
          vim.fn.cursor(e, vim.fn.col({ e, "$" }))
        end, { desc = "Select cell content" })

        map("n", "vic", function()
          local s, e = select_cell()
          vim.fn.cursor(s, 1)
          vim.cmd("normal! V")
          vim.fn.cursor(e, vim.fn.col({ e, "$" }))
        end, { desc = "Select cell" })

        -- Notebook conversion: .ipynb -> .py with percent cells
        map("n", "<leader>jp", function()
          local f = vim.fn.expand("%:p")
          if f:match("%.ipynb$") then
            local out = f:gsub("%.ipynb$", ".py")
            local cmd = "jupytext --to py:percent --output " .. vim.fn.shellescape(out) .. " " .. vim.fn.shellescape(f)
            local res = vim.fn.system(cmd)
            if vim.v.shell_error == 0 then
              vim.notify("Converted to " .. vim.fn.fnamemodify(out, ":t"))
              vim.cmd("edit " .. out)
            else
              vim.notify("Conversion failed: " .. res, vim.log.levels.ERROR)
              vim.notify("Is jupytext installed? Try: pip install jupytext", vim.log.levels.INFO)
            end
          else
            vim.notify("Not a .ipynb file", vim.log.levels.WARN)
          end
        end, { desc = "Convert .ipynb to .py" })

        -- .py -> .ipynb
        map("n", "<leader>jw", function()
          local f = vim.fn.expand("%:p")
          if f:match("%.py$") then
            local out = f:gsub("%.py$", ".ipynb")
            vim.fn.system("jupytext --to ipynb --output " .. vim.fn.shellescape(out) .. " " .. vim.fn.shellescape(f))
            if vim.v.shell_error == 0 then
              vim.notify("Converted to " .. vim.fn.fnamemodify(out, ":t"))
            else
              vim.notify("Conversion failed. Is jupytext installed?", vim.log.levels.ERROR)
            end
          end
        end, { desc = "Write to .ipynb" })
      end

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

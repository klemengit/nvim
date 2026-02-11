-- Jupyter-like workflow using toggleterm + IPython (robust block sending)
-- Navigation and cell text objects are delegated to NotebookNavigator + mini.ai.
-- Each file gets its own IPython REPL instance (like per-notebook kernels).

return {
  {
    "akinsho/toggleterm.nvim",
    dependencies = { "GCBallesteros/NotebookNavigator.nvim" },
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

      -- Cell marker pattern for bulk runners (run_cells_above, run_all_cells)
      local CELL_MARK = "^%s*#%s*%%%%"

      -- Build IPython command
      local function ipython_cmd()
        return "ipython --no-banner --automagic --colors=Linux"
      end

      -- Per-file REPL registry: filepath -> { term = Terminal, initialized = bool }
      local repls = {}
      local next_count = 2

      local function current_filepath()
        return vim.fn.expand("%:p")
      end

      local function get_repl(filepath)
        filepath = filepath or current_filepath()
        if not repls[filepath] then
          repls[filepath] = {
            term = Terminal:new({
              cmd = ipython_cmd(),
              dir = "git_dir",
              direction = "vertical",
              count = next_count,
            }),
            initialized = false,
          }
          next_count = next_count + 1
        end
        return repls[filepath]
      end

      -- Ensure REPL for the current file is open
      local function ensure_repl_ready()
        local repl = get_repl()
        if not repl.term:is_open() then
          repl.term:open()
        end
      end

      -- Poll the terminal buffer for IPython's "In [" prompt, then fire callback
      local function wait_for_ipython(callback)
        local repl = get_repl()
        local timer = vim.uv.new_timer()
        local elapsed = 0
        timer:start(
          50,
          50,
          vim.schedule_wrap(function()
            elapsed = elapsed + 50
            local bufnr = repl.term.bufnr
            if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
              local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
              for _, line in ipairs(lines) do
                if line:match("In %[%d+%]") then
                  timer:stop()
                  timer:close()
                  callback()
                  return
                end
              end
            end
            if elapsed >= 10000 then
              timer:stop()
              timer:close()
              callback() -- send anyway after 10s timeout
            end
          end)
        )
      end

      -- Helpers
      local function rstrip_newlines(s)
        return (s:gsub("\n+$", "")) -- drop all trailing newlines
      end

      -- Robust sender: bracketed paste (best) or %cpaste fallback
      local function send_to_repl(text, opts)
        opts = opts or {}
        local use_cpaste = opts.cpaste or vim.g.jupyter_use_cpaste

        local repl = get_repl()
        local needs_init = not repl.initialized
        ensure_repl_ready()

        -- Strip trailing newlines to avoid creating an extra empty cell
        text = rstrip_newlines(text)

        local function do_send()
          if not use_cpaste then
            -- Bracketed paste: one atomic block + exactly one Enter outside the paste
            local START, END = "\x1b[200~", "\x1b[201~"
            repl.term:send(START .. text .. END .. "\n", false)
          else
            -- cpaste mode: send text and terminate with `--`
            repl.term:send("%cpaste -q\n", false)
            repl.term:send(text .. "\n", false)
            repl.term:send("--\n", false)
          end

          -- Return focus to previous window
          vim.cmd("wincmd p")
        end

        if needs_init then
          repl.initialized = true
          wait_for_ipython(do_send)
        else
          do_send()
        end
      end

      -- Expose a simple toggle to switch paste mode at runtime
      vim.api.nvim_create_user_command("JupyterPasteMode", function()
        vim.g.jupyter_use_cpaste = not vim.g.jupyter_use_cpaste
        vim.notify(
          "Jupyter paste mode: " .. (vim.g.jupyter_use_cpaste and "%cpaste" or "bracketed"),
          vim.log.levels.INFO
        )
      end, { desc = "Toggle between bracketed paste and %cpaste" })

      -- -------------
      -- Runners
      -- -------------

      local function run_cell(move_to_next)
        move_to_next = move_to_next or false
        local region = require("notebook-navigator").miniai_spec("i")
        if region then
          local lines = vim.api.nvim_buf_get_lines(0, region.from.line - 1, region.to.line, false)
          local code = table.concat(lines, "\n")
          if code:match("%S") then
            send_to_repl(code)
          end
        end
        if move_to_next then
          require("notebook-navigator").move_cell("d")
        end
      end

      local function run_cell_move_to_next()
        run_cell(true)
      end

      local function run_cells_above()
        local cur = vim.fn.line(".")
        local starts = { 1 }
        for i = 1, cur do
          if vim.fn.getline(i):match(CELL_MARK) then
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
          vim.notify("Executed " .. #chunks .. " cells above")
        else
          vim.notify("No cells found above current position")
        end
      end

      local function run_all_cells()
        local last = vim.fn.line("$")
        local starts = { 1 }
        for i = 1, last do
          if vim.fn.getline(i):match(CELL_MARK) then
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
          vim.notify("Executed " .. #chunks .. " cells")
        else
          vim.notify("No cells found in file")
        end
      end

      local function run_line()
        send_to_repl(vim.fn.getline("."))
      end

      local function run_selection()
        local s_line = vim.fn.line("v")
        local e_line = vim.fn.line(".")
        if s_line > e_line then
          s_line, e_line = e_line, s_line
        end
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "x", false)
        local lines = vim.api.nvim_buf_get_lines(0, s_line - 1, e_line, false)
        send_to_repl(table.concat(lines, "\n"))
      end

      local function smart_toggle_repl()
        local repl = get_repl()
        if repl.term:is_open() then
          repl.term:close() -- hides, keeps process
        else
          repl.term:open()
          vim.cmd("wincmd p")
        end
      end

      -- ----------------
      -- Buffer-local keymaps
      -- ----------------

      local function setup_jupyter_keymaps(bufnr)
        local map = vim.keymap.set
        local function buf_opts(desc)
          return { buffer = bufnr, desc = desc }
        end

        -- Exec
        map("n", "<leader>jc", run_cell_move_to_next, buf_opts("Run current cell and move to next cell"))
        map("n", "<leader>jC", function()
          run_cell(false)
        end, buf_opts("Run current cell and stay put"))
        map("n", "<leader>jl", run_line, buf_opts("Run current line"))
        map("v", "<leader>jl", run_selection, buf_opts("Run selection"))
        map("n", "<leader>ja", run_cells_above, buf_opts("Run all cells above"))
        map("n", "<leader>jf", run_all_cells, buf_opts("Run all cells in file"))

        -- Cells (delegated to NotebookNavigator)
        map("n", "<leader>jn", function()
          require("notebook-navigator").add_cell_below()
        end, buf_opts("Create cell below"))
        map("n", "<leader>jj", function()
          require("notebook-navigator").move_cell("d")
        end, buf_opts("Next cell"))
        map("n", "<leader>jk", function()
          require("notebook-navigator").move_cell("u")
        end, buf_opts("Previous cell"))

        -- REPL visibility & lifecycle
        map("n", "<leader>jt", smart_toggle_repl, buf_opts("Toggle REPL visibility"))
        map("n", "<leader>jR", function()
          local repl = get_repl()
          ensure_repl_ready()
          repl.term:send("%reset -f\n", false)
        end, buf_opts("IPython reset (keep session)"))
        map("n", "<leader>jr", function()
          local repl = get_repl()
          ensure_repl_ready()
          repl.term:send("%clear\n", false)
          vim.cmd("wincmd p")
        end, buf_opts("Clear IPython screen"))

        map("n", "<leader>jx", function()
          local filepath = current_filepath()
          local repl = repls[filepath]
          if repl and repl.term:is_open() then
            repl.term:shutdown()
            repls[filepath] = nil
            vim.notify("REPL terminated for " .. vim.fn.fnamemodify(filepath, ":t"))
          else
            vim.notify("No REPL running for this file")
          end
        end, buf_opts("Exit and destroy REPL"))

        -- Quick helpers
        map("n", "<leader>ji", function()
          send_to_repl("plt.show()")
        end, buf_opts("Show plots"))

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
        end, buf_opts("Convert .ipynb to .py"))

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
        end, buf_opts("Write to .ipynb"))
      end

      local augroup = vim.api.nvim_create_augroup("JupyterSimple", { clear = true })

      -- Auto-setup for Python files (covers .ipynb via jupytext's ft detection)
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = "python",
        callback = function(args)
          setup_jupyter_keymaps(args.buf)
        end,
      })

      -- Auto-swap REPL when switching between Python files
      vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        callback = function()
          if vim.bo.filetype ~= "python" then
            return
          end

          local filepath = current_filepath()

          -- Close any REPL not belonging to the current file
          local had_open = false
          for fp, repl in pairs(repls) do
            if fp ~= filepath and repl.term:is_open() then
              repl.term:close()
              had_open = true
            end
          end

          -- If a REPL was visible, show the current file's REPL (if it exists)
          local cur_repl = repls[filepath]
          if had_open and cur_repl and not cur_repl.term:is_open() then
            cur_repl.term:open()
            vim.cmd("wincmd p")
          end
        end,
      })
    end,
  },
}

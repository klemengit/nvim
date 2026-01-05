-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function activate_venv()
  -- Check if we're in a terminal
  if vim.bo.buftype ~= "terminal" then
    vim.notify("Not in terminal buffer", vim.log.levels.WARN)
    return
  end

  -- Check for virtual environment
  local venv_paths = { "./venv/bin/activate", "./.venv/bin/activate" }
  local activate_cmd = nil

  for _, path in ipairs(venv_paths) do
    if vim.fn.filereadable(path) == 1 then
      activate_cmd = "source " .. path
      break
    end
  end

  if not activate_cmd then
    vim.notify("No venv found (looking for venv/ or .venv/)", vim.log.levels.WARN)
    return
  end

  -- Send command without startinsert, but with proper formatting
  local bufnr = vim.api.nvim_get_current_buf()
  local job_id = vim.b[bufnr].terminal_job_id
  if job_id then
    -- Clear any partial input first, then send the command
    vim.fn.chansend(job_id, "\03") -- Send Ctrl+C to clear line
    vim.defer_fn(function()
      vim.fn.chansend(job_id, activate_cmd .. "\n") -- Use \n instead of \r
    end, 200) -- Longer delay
    vim.notify("Virtual environment activated", vim.log.levels.INFO)
  else
    vim.notify("Terminal job not found", vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command("ActivateVenv", activate_venv, {})

-- Disable the 'q' register for macro recording
vim.api.nvim_create_autocmd("RecordingEnter", {
  callback = function()
    local reg = vim.fn.reg_recording()
    if reg == "q" then
      vim.cmd("normal! q") -- Stop recording immediately
      vim.notify('Recording to register "q" is disabled', vim.log.levels.WARN)
    end
  end,
})

-- disable the automatic commenting when pressing `o` in a commented line
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    -- vim.opt_local.formatoptions:remove({ "o", "r" }) -- Also disable continuing the comment when pressing Enter in insert mode.
    vim.opt_local.formatoptions:remove({ "o" })
  end,
})

-- ---------------------------------------------------------------------------
-- Add a visual separator to the notebook cells (molten)
local function update_cell_separators()
  local ns = vim.api.nvim_create_namespace("molten_cells")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  
  for i = 1, vim.api.nvim_buf_line_count(0) do
    local line = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1]
    if line and line:match("^# %%") then
      vim.api.nvim_buf_set_extmark(0, ns, i-1, 0, {
        virt_lines = { { { string.rep("─", 500), "Comment" } } },
        virt_lines_above = true,
      })
    end
  end
end

local timer = nil
vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
  pattern = {"*.py", "*.ipynb"},
  callback = function()
    if timer then
      vim.fn.timer_stop(timer)
    end
    timer = vim.fn.timer_start(500, update_cell_separators)
  end,
})

vim.api.nvim_create_autocmd({"BufEnter"}, {
  pattern = {"*.py", "*.ipynb"},
  callback = update_cell_separators,
})

vim.api.nvim_create_autocmd({"FileType"}, {
  pattern = {"python", "ipynb"},
  callback = update_cell_separators,
})
-- ---------------------------------------------------------------------------

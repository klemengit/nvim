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

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode with jj" })

-- Text object for cell (like `iw` for word, `ip` for paragraph)
vim.keymap.set({ "o", "x" }, "ic", function()
  local CELL_MARK = "^%s*#%s*%%%%"
  local cur = vim.fn.line(".")
  local last = vim.fn.line("$")

  -- Find cell start
  local start_line = cur
  for i = cur, 1, -1 do
    local line = vim.fn.getline(i)
    if line:match(CELL_MARK) then
      start_line = i + 1
      break
    elseif i == 1 then
      start_line = 1
      break
    end
  end

  -- Find cell end
  local end_line = last
  for i = cur + 1, last do
    local line = vim.fn.getline(i)
    if line:match(CELL_MARK) then
      end_line = i - 1
      break
    end
  end

  -- Trim empty lines
  while start_line <= end_line and vim.fn.getline(start_line):match("^%s*$") do
    start_line = start_line + 1
  end
  while end_line >= start_line and vim.fn.getline(end_line):match("^%s*$") do
    end_line = end_line - 1
  end

  -- Select the range
  if start_line <= end_line then
    vim.fn.cursor(start_line, 1)
    vim.cmd("normal! V")
    vim.fn.cursor(end_line, vim.fn.col({ end_line, "$" }))
  end
end, { desc = "inner cell" })

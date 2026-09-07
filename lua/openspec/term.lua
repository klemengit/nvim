-- Floating `openspec view` dashboard.
--
-- `openspec view` prints a report and exits, so a buffer is only ever good for
-- one run. Every open tears down the previous float to force a fresh run.

local M = {}

local term = nil

local function terms()
  return term and term.terms or {}
end

local function is_open()
  for _, t in pairs(terms()) do
    if t.win and vim.api.nvim_win_is_valid(t.win) then
      return true
    end
  end
  return false
end

-- Tear down every float we own: window first (deleting the buffer first leaves
-- the window open with another buffer swapped into it), then the buffer, then
-- the cache entry so the next open re-runs the command.
local function discard()
  for id, t in pairs(terms()) do
    if t.win and vim.api.nvim_win_is_valid(t.win) then
      pcall(vim.api.nvim_win_close, t.win, true)
    end
    if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
      for _, win in ipairs(vim.fn.win_findbuf(t.buf)) do
        pcall(vim.api.nvim_win_close, win, true)
      end
      pcall(vim.api.nvim_buf_delete, t.buf, { force = true })
    end
    terms()[id] = nil
  end
end

function M.setup()
  term = require("floatty").setup({
    cmd = "openspec view",
    id = vim.fn.getcwd,
    start_in_insert = false,
    on_open = function(_, buf)
      vim.keymap.set({ "n", "t" }, "q", M.close, { buffer = buf, desc = "Close OpenSpec" })
      vim.keymap.set({ "n", "t" }, "r", M.refresh, { buffer = buf, desc = "Refresh OpenSpec dashboard" })
    end,
    window = {
      width = 0.8,
      height = 0.8,
      border = "rounded",
      title = " OpenSpec ",
      title_pos = "center",
    },
  })
  return term
end

local function ensure()
  if not term then
    M.setup()
  end
end

function M.close()
  ensure()
  discard()
end

function M.open()
  ensure()
  discard()
  term.toggle()
end

function M.toggle()
  ensure()
  if is_open() then
    discard()
  else
    M.open()
  end
end

M.refresh = M.open

return M

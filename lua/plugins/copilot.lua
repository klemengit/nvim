return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = false, -- Disable automatic suggestions
      keymap = {
        accept = "<Enter>", -- Accept suggestion with Tab
        next = "<M-]>", -- Next suggestion with Alt+]
        prev = "<M-[>", -- Previous suggestion with Alt+[
        dismiss = "<C-]>", -- Dismiss suggestion with Ctrl+]
      },
    },
    panel = { enabled = false }, -- Disable panel, we'll use inline only
    filetypes = {
      -- markdown = false, -- Optionally disable for certain filetypes
      help = false,
    },
  },
  keys = {
    {
      "<C-s>",
      function()
        require("copilot.suggestion").next()
      end,
      mode = "i",
      desc = "Copilot suggest",
    },
  },
}

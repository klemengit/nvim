return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<A-t>",
        function()
          Snacks.terminal()
        end,
        mode = { "n", "i", "t" },
        desc = "Toggle Terminal",
      },
    },
  },
}

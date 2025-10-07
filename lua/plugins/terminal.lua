return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<C-S-/>",
        function()
          Snacks.terminal()
        end,
        mode = { "n", "t" },
        desc = "Toggle Terminal",
      },
    },
  },
}

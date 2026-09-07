return {
  {
    "ingur/floatty.nvim",
    lazy = true,
    keys = {
      {
        "<leader>os",
        function()
          require("openspec.term").toggle()
        end,
        desc = "OpenSpec View",
      },
    },
    config = function()
      require("openspec.term").setup()
    end,
  },
}
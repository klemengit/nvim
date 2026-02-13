return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      if vim.g.lightweight then
        table.insert(opts.sections.lualine_x, 1, {
          function()
            return "NVIM LIGHT"
          end,
          color = { fg = "#ff9e64" },
        })
      end
    end,
  },
}

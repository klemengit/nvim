return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, c)
        -- Brighter comments (default is ~#565f89, bumped up for readability)
        hl.Comment = { fg = "#7c87b8", italic = true }
        -- Molten virtual text output: warm yellow, distinct from blue comments
        hl.MoltenVirtualText = { fg = "#73daca" }
      end,
    },
  },
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

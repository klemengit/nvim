return {
  "neovim/nvim-lspconfig",
  cond = not vim.g.lightweight,
  opts = {
    servers = {
      pyright = {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "off", -- "off" | "basic" | "strict"
            },
          },
        },
      },
    },
  },
}

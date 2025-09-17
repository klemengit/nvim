return {
  "neovim/nvim-lspconfig",
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

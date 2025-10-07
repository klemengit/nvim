-- add any tools you want to have installed below
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "prettier",
        "shfmt",
        "flake8",
        "pyright",
      },
    },
  },
}

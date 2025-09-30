return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      -- Only Prettier for Markdown (no markdownlint)
      opts.formatters_by_ft.markdown = { "prettier" }
      opts.formatters_by_ft["markdown.mdx"] = { "prettier" }

      -- Configure Prettier: 160 print width, don't hard-wrap prose
      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = {
        -- use project/.prettierrc if present; otherwise enforce below args
        prepend_args = {
          "--print-width",
          "160",
          "--prose-wrap",
          "preserve",
        },
      }

      -- optional: never fall back to LSP formatting for Markdown
      -- (keeps lua_ls etc. from touching md by accident)
      opts.lsp_format = opts.lsp_format or "fallback"
      return opts
    end,
  },
}

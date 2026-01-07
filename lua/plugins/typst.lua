return {
  {
    'chomosuke/typst-preview.nvim',
    lazy = false, -- or ft = 'typst'
    version = '1.*',
    opts = {}, -- lazy.nvim will implicitly calls `setup {}`
    keys = {
      { "<leader>tp", ":TypstPreviewToggle<CR>", desc = "Toggle typst preview" },
      {
          "<leader>tw",
          function()
              local current_file = vim.fn.expand("%:p")
              if vim.fn.filereadable(current_file) == 1 and current_file:match("%.typ$") then
                  -- Open terminal in new buffer and run typst watch
                  vim.cmd("enew | terminal typst watch " .. vim.fn.shellescape(current_file))
                  -- Open the PDF after a short delay (to allow typst to generate it)
                  vim.defer_fn(function()
                      local pdf_file = current_file:gsub("%.typ$", ".pdf")
                      if vim.fn.filereadable(pdf_file) == 1 then
                          vim.cmd("!xdg-open " .. vim.fn.shellescape(pdf_file))
                      else
                          print("PDF not found: " .. pdf_file)
                      end
                  end, 1000) -- 1 second delay
              else
                  print("Not a Typst file or file does not exist.")
              end
          end,
          desc = "Run Typst watch and open PDF"
      },
    }
  }
}

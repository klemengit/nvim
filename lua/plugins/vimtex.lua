-- return {
--   "lervag/vimtex",
--   lazy = false,
--   init = function()
--     -- Ensure filetype detection + LaTeX flavor
--     vim.g.do_filetype_lua = 1
--     vim.g.did_load_filetypes = 0
--     vim.g.tex_flavor = "latex"
--     -- Disable syntax conceal (partial live rendering)
--     vim.g.vimtex_syntax_conceal_disable = 1
--
--     -- Viewer: use "general" with Okular
--     vim.g.vimtex_view_method = "general"
--     vim.g.vimtex_view_general_viewer = "okular"
--     -- Use Lua long string so you don't have to double-escape '#'
--     vim.g.vimtex_view_general_options = [[--unique @pdf\#src:@line@tex]]
--
--     -- Compiler with synctex
--     vim.g.vimtex_compiler_method = "latexmk"
--     vim.g.vimtex_compiler_latexmk = {
--       options = { "-pdf", "-synctex=1", "-interaction=nonstopmode", "-file-line-error" },
--     }
--
--     -- Default vimtex mappings (so \l… exists)
--     vim.g.vimtex_mappings_enabled = 1
--     vim.g.maplocalleader = "\\"
--   end,
--   -- config = function()
--   --   -- Optional: explicit keymaps so which-key shows a simple '\v'
--   --   vim.keymap.set("n", "<localleader>v", "<cmd>VimtexView<CR>", { desc = "VimTeX: View (Okular)" })
--   --   vim.keymap.set("n", "<localleader>ll", "<cmd>VimtexCompile<CR>", { desc = "VimTeX: Compile" })
--   -- end,
-- }

return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    -- Ensure filetype detection + LaTeX flavor
    vim.g.do_filetype_lua = 1
    vim.g.did_load_filetypes = 0
    vim.g.tex_flavor = "latex"
    -- Disable syntax conceal (partial live rendering)
    vim.g.vimtex_syntax_conceal_disable = 1

    -- Viewer: use "general" with Okular
    vim.g.vimtex_view_method = "general"
    vim.g.vimtex_view_general_viewer = "okular"
    -- Use Lua long string so you don't have to double-escape '#'
    vim.g.vimtex_view_general_options = [[--unique @pdf\#src:@line@tex]]

    -- Compiler with synctex + glossaries support
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      options = {
        "-pdf",
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-shell-escape", -- Required for glossaries
      },
      -- Enable glossaries processing
      build_dir = "",
      callback = 1,
      continuous = 1,
      executable = "latexmk",
    }

    -- Default vimtex mappings (so \l… exists)
    vim.g.vimtex_mappings_enabled = 1
    vim.g.maplocalleader = "\\"
  end,
  config = function()
    -- Create .latexmkrc content for glossaries support
    local function create_latexmkrc()
      local cwd = vim.fn.getcwd()
      local latexmkrc_path = cwd .. "/.latexmkrc"

      -- Check if .latexmkrc already exists
      if vim.fn.filereadable(latexmkrc_path) == 0 then
        local latexmkrc_content = [[
# Glossaries support
add_cus_dep('glo', 'gls', 0, 'run_makeglossaries');
add_cus_dep('acn', 'acr', 0, 'run_makeglossaries');

sub run_makeglossaries {
  if ( $silent ) {
    system "makeglossaries -q '$_[0]'";
  } else {
    system "makeglossaries '$_[0]'";
  }
}

# Clean up glossaries files
$clean_ext .= ' %R.ist %R.xdy';
$clean_ext .= ' %R.acr %R.acn %R.alg';
$clean_ext .= ' %R.glg %R.glo %R.gls';
$clean_ext .= ' %R.glsdefs';
]]

        local file = io.open(latexmkrc_path, "w")
        if file then
          file:write(latexmkrc_content)
          file:close()
          vim.notify("Created .latexmkrc for glossaries support", vim.log.levels.INFO)
        end
      end
    end

    -- Auto-create .latexmkrc when opening LaTeX files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "tex",
      callback = create_latexmkrc,
    })

    -- Optional: keymaps for manual glossaries operations
    vim.keymap.set("n", "<localleader>lg", function()
      local filename = vim.fn.expand("%:r")
      vim.fn.system("makeglossaries " .. filename)
      vim.notify("Ran makeglossaries on " .. filename, vim.log.levels.INFO)
    end, { desc = "VimTeX: Run makeglossaries" })
  end,
}

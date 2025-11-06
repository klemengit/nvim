return {
  "lervag/vimtex",
  lazy = true,
  init = function()
    -- Ensure filetype detection + LaTeX flavor
    vim.g.do_filetype_lua = 1
    vim.g.did_load_filetypes = 0
    vim.g.tex_flavor = "latex"
    -- Disable syntax conceal (partial live rendering)
    vim.g.vimtex_syntax_conceal_disable = 1

    -- Cross-platform PDF viewer detection
    local viewer, options
    if vim.fn.has("mac") == 1 then
      viewer = "skim"
      options = "-r -g @line @pdf @tex"
    elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      viewer = "sumatrapdf"
      options = "-reuse-instance -forward-search @tex @line @pdf"
    else
      -- Linux/Unix - try common viewers
      if vim.fn.executable("okular") == 1 then
        viewer = "okular"
        options = [[--unique @pdf\#src:@line@tex]]
      elseif vim.fn.executable("zathura") == 1 then
        viewer = "zathura"
        options = "--synctex-forward @line:@col:@tex @pdf"
      elseif vim.fn.executable("evince") == 1 then
        viewer = "evince"
        options = "@pdf"
      else
        viewer = "xdg-open"
        options = "@pdf"
      end
    end

    vim.g.vimtex_view_method = "general"
    vim.g.vimtex_view_general_viewer = viewer
    vim.g.vimtex_view_general_options = options

    -- Compiler with synctex
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      options = { "-pdf", "-synctex=1", "-interaction=nonstopmode", "-file-line-error" },
    }

    -- Default vimtex mappings (so \l… exists)
    vim.g.vimtex_mappings_enabled = 1
    vim.g.maplocalleader = "\\"
  end,
  config = function()
    -- Optional: explicit keymaps so which-key shows a simple '\v'
    vim.keymap.set("n", "<localleader>v", "<cmd>VimtexView<CR>", { desc = "VimTeX: View PDF" })
    vim.keymap.set("n", "<localleader>ll", "<cmd>VimtexCompile<CR>", { desc = "VimTeX: Compile" })
  end,
}

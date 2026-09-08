# 💤 LazyVim Neovim Configuration

A reproducible Neovim configuration based on [LazyVim](https://github.com/LazyVim/LazyVim) with
cross-platform support and automated setup.

## 🚀 Quick Installation

```bash
# Clone this configuration
git clone git@github.com:klemengit/nvim.git ~/.config/nvim

# Install manually (see Manual Installation below)
```

## 📋 Prerequisites

### Required

- **Neovim >= 0.9.0** (recommended: 0.10.0+)
- **Git** (for plugin management)
- **A terminal with true color support**

### Optional (for full functionality)

- **LaTeX distribution** (for VimTeX plugin)
  - Linux: `sudo apt install texlive-full` or `sudo pacman -S texlive-most`
  - macOS: Install MacTeX from [tug.org/mactex](https://tug.org/mactex/)
  - Windows: Install MiKTeX from [miktex.org](https://miktex.org/)
- **PDF viewer** (auto-detected):
  - Linux: Okular, Zathura, or Evince
  - macOS: Skim
  - Windows: SumatraPDF

## 🛠 Manual Installation

### 1. Install Neovim

#### Linux (Ubuntu/Debian)

```bash
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
```

#### Linux (Arch)

```bash
sudo pacman -S neovim
```

#### macOS

```bash
brew install neovim
```

#### Windows

Download from [neovim.io](https://neovim.io/) or use Chocolatey:

```powershell
choco install neovim
```

### 2. Clone Configuration

```bash
# Backup existing config (if any)
mv ~/.config/nvim ~/.config/nvim.backup

# Clone this repo
git clone git@github.com:klemengit/nvim.git ~/.config/nvim
cd ~/.config/nvim
```

### 3. Install Language Servers & Tools

The configuration uses Mason for LSP management, but some servers need manual installation:

#### Python Development

```bash
# Install Pyright LSP (required for Python support)
# This must be done inside Neovim:
nvim
:MasonInstall pyright
```

#### Node.js Development

```bash
# Install Node.js LSP
nvim
:MasonInstall typescript-language-server eslint-d prettier
```

#### Other Languages

```bash
# Inside Neovim, install servers for your languages:
:Mason
# Use UI to install: lua-language-server, rust-analyzer, etc.
```

### 4. First Launch

```bash
nvim
```

On first launch:

1. Lazy.nvim will automatically install all plugins
2. Wait for installation to complete
3. Restart Neovim: `:q` then `nvim`
4. Install language servers: `:Mason`

## 🔧 Configuration Structure

```
~/.config/nvim/
├── init.lua                 # Entry point
├── lazy-lock.json          # Plugin version lock (DO NOT DELETE)
├── lazyvim.json            # LazyVim configuration
├── stylua.toml             # Lua formatting config
├── lua/
│   ├── config/
│   │   ├── autocmds.lua    # Auto commands
│   │   ├── keymaps.lua     # Key mappings
│   │   ├── lazy.lua        # Plugin manager setup
│   │   └── options.lua     # Neovim options
│   └── plugins/
│       ├── example.lua     # Example plugin config
│       └── vimtex.lua      # LaTeX support
├── DEPENDENCIES.md         # System requirements
└── .github/
    └── workflows/
        └── test.yml        # CI testing
```

## 🎯 Key Features

- **Cross-platform PDF viewer detection** for LaTeX
- **Pinned plugin versions** via `lazy-lock.json`
- **Cross-platform compatibility** with OS detection
- **LSP auto-installation** via Mason
- **Consistent socket configuration** for external tools
- **CI testing** on multiple platforms

## 🔍 Troubleshooting

### Plugin Issues

```bash
# Clear plugin cache and reinstall
rm -rf ~/.local/share/nvim
nvim
```

### LSP Not Working

```bash
# Check LSP status
:LspInfo

# Reinstall language server
:Mason
# Select server and press 'X' to uninstall, then 'i' to install
```

### LaTeX/VimTeX Issues

```bash
# Check if LaTeX is installed
latex --version

# Check PDF viewer
which okular  # Linux
which skim    # macOS
```

### Performance Issues

```bash
# Profile startup time
nvim --startuptime startup.log
```

## 🤝 Contributing

1. Test changes on multiple platforms
2. Update `lazy-lock.json` after adding plugins
3. Test on multiple platforms before submitting
4. Document any new dependencies

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

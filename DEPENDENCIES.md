# System Dependencies

This document outlines all system dependencies required for the full functionality of this Neovim configuration.

## Core Requirements

### Neovim

- **Version**: >= 0.9.0 (recommended: 0.10.0+)
- **Installation**:
  - Linux: `sudo apt install neovim` or `sudo pacman -S neovim`
  - macOS: `brew install neovim`
  - Windows: Download from [neovim.io](https://neovim.io/)

### Git

- **Purpose**: Plugin management via lazy.nvim
- **Installation**:
  - Linux: `sudo apt install git` or `sudo pacman -S git`
  - macOS: `xcode-select --install` or `brew install git`
  - Windows: Download from [git-scm.com](https://git-scm.com/)

### Terminal with True Color Support

- **Examples**: Alacritty, WezTerm, iTerm2, Windows Terminal
- **Test**: `echo $COLORTERM` should show `truecolor` or `24bit`

## Language Servers (LSP)

These are automatically managed by Mason, but some may require manual installation:

### Python

- **pyright** - Primary Python LSP
- **black** - Code formatter (optional)
- **isort** - Import sorter (optional)
- **Installation**: `:MasonInstall pyright black isort`

### JavaScript/TypeScript

- **typescript-language-server** - TS/JS LSP
- **eslint-d** - Linting
- **prettier** - Code formatting
- **Installation**: `:MasonInstall typescript-language-server eslint-d prettier`

### Lua

- **lua-language-server** - Lua LSP
- **stylua** - Lua formatter
- **Installation**: `:MasonInstall lua-language-server stylua`

### Rust

- **rust-analyzer** - Rust LSP
- **Installation**: `:MasonInstall rust-analyzer`

### Go

- **gopls** - Go LSP
- **Installation**: `:MasonInstall gopls`

### C/C++

- **clangd** - C/C++ LSP
- **Installation**: `:MasonInstall clangd`

## LaTeX Support (VimTeX Plugin)

### LaTeX Distribution

#### Linux

```bash
# Ubuntu/Debian
sudo apt install texlive-full

# Arch Linux
sudo pacman -S texlive-most texlive-lang

# Fedora
sudo dnf install texlive-scheme-full
```

#### macOS

```bash
# Install MacTeX (recommended)
# Download from: https://tug.org/mactex/

# Or via Homebrew (smaller installation)
brew install --cask mactex-no-gui
brew install basictex
```

#### Windows

```powershell
# Install MiKTeX
# Download from: https://miktex.org/

# Or via Chocolatey
choco install miktex
```

### PDF Viewers (Auto-detected)

#### Linux

The configuration automatically detects and uses the first available:

1. **Okular** (KDE) - `sudo apt install okular`
2. **Zathura** - `sudo apt install zathura`
3. **Evince** (GNOME) - `sudo apt install evince`
4. **xdg-open** (fallback)

#### macOS

- **Skim** (recommended) - Download from [skim-app.sourceforge.io](https://skim-app.sourceforge.io/)
- **Preview** (built-in, fallback)

#### Windows

- **SumatraPDF** (recommended) - Download from [sumatrapdfreader.org](https://www.sumatrapdfreader.org/)

### LaTeX Tools

```bash
# Usually included with LaTeX distributions
latexmk    # Build automation
pdflatex   # PDF compilation
bibtex     # Bibliography processing
```

## Optional Dependencies

### Clipboard Support

#### Linux

```bash
# X11
sudo apt install xclip
# or
sudo apt install xsel

# Wayland
sudo apt install wl-clipboard
```

#### macOS

- Built-in (`pbcopy`/`pbpaste`)

#### Windows

- Built-in

### Ripgrep (Enhanced Search)

```bash
# Linux
sudo apt install ripgrep
# or
sudo pacman -S ripgrep

# macOS
brew install ripgrep

# Windows
choco install ripgrep
```

### fd (Enhanced File Finding)

```bash
# Linux
sudo apt install fd-find
# or
sudo pacman -S fd

# macOS
brew install fd

# Windows
choco install fd
```

### Node.js (For Various Plugins)

```bash
# Linux
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS
brew install node

# Windows
choco install nodejs
```

## Development Tools

### Python Development

```bash
# Virtual environment support
python3 -venv
# or
pip install virtualenv

# Additional tools
pip install black isort flake8 mypy
```

### Node.js Development

```bash
npm install -g typescript eslint prettier
```

### Rust Development

```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Verification Commands

Run these commands to verify your installation:

```bash
# Core tools
nvim --version
git --version

# Language servers (after Mason installation)
pyright --version
typescript-language-server --version

# LaTeX (if using VimTeX)
latex --version
latexmk --version

# Optional tools
rg --version
fd --version
node --version
```

## Troubleshooting

### Missing Language Server

```bash
# Check Mason status
nvim
:Mason
:MasonLog
```

### LaTeX Issues

```bash
# Check LaTeX installation
which latex
which pdflatex
which latexmk

# Check PDF viewer
which okular    # Linux
which skim      # macOS
which sumatrapdf # Windows
```

### Clipboard Issues

```bash
# Test clipboard
echo "test" | nvim -c 'put +' -c 'wq'

# Install clipboard provider
# See clipboard support section above
```

# 🚀 Universal Development Environment Setup

> An intelligent, idempotent setup script that works across **any Linux distribution**, WSL, and Git Bash. Configure a complete development environment with modern tools, beautiful shell, and your preferred theme in minutes.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL%20%7C%20Git%20Bash-blue.svg)](https://github.com/ThiagoSantosOFC/starship)

## ✨ Features

- 🌍 **Universal**: Works on Ubuntu, Debian, Fedora, AlmaLinux, Rocky, Arch, Alpine, openSUSE, and more
- 🔄 **Idempotent**: Safe to run multiple times - skips what's already installed
- 🎨 **Beautiful**: Includes Starship prompt with custom Dracula Plus theme
- 🤖 **AI-Friendly**: Aliases don't break scripts or AI tools behavior
- 🛡️ **Robust**: Comprehensive error handling with detailed reporting
- 📦 **Complete**: Installs 20+ modern CLI tools and 5 programming languages
- ⚡ **Fast**: Smart detection and parallel installations where possible

## 🎯 What Gets Installed

### 💻 Languages & Runtimes
- **Rust** (via rustup)
- **Node.js** (via nvm - version manager)
- **Python 3** + pipx
- **Go** (official distribution)
- **GCC/G++** (C/C++ compiler toolchain)

### 📦 Node.js Package Managers
Interactive choice between:
- npm (included with Node.js)
- yarn
- pnpm
- bun
- All of the above

### 🎨 Modern CLI Tools
| Tool | Replaces | Description |
|------|----------|-------------|
| **bat** | cat | Syntax highlighting viewer |
| **exa** | ls | Modern, colorful file listing |
| **fd** | find | Fast file search |
| **ripgrep** | grep | Ultra-fast text search |
| **dust** | du | Visual disk usage |
| **zoxide** | cd | Smart directory jumper |
| **starship** | prompt | Fast, customizable prompt |
| **fzf** | - | Fuzzy finder |
| **btop** | top/htop | Beautiful system monitor |
| **lazygit** | git | Git TUI interface |
| **delta** | git diff | Better git diffs |
| **tldr** | man | Practical command examples |

### 🐳 Container Runtimes (Optional)
- Docker Engine (native)
- Docker Desktop (WSL integration)
- Podman (Docker alternative)

### 💻 Editors
- **nano** (simple editor)
- **LazyVim** (complete Neovim setup)
  - LSP support for Python, JS/TS, Go, Rust, C/C++
  - Treesitter syntax highlighting
  - Telescope fuzzy finder
  - Neo-tree file explorer
  - Full Git integration

### 🎨 Shell & Theme
- **Zsh** with plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - zsh-completions
- **Starship** prompt with **Dracula Plus** theme
- AI-friendly aliases (don't break scripts)

### 🔤 Fonts
- FiraCode Nerd Font
- JetBrainsMono Nerd Font

### 🔧 Additional Features
- Interactive Git configuration
- Optional SSH key generation (ED25519)
- Dotfiles management system (Git-based)
- Utility scripts (sysinfo, cleanup, dotfiles-*)

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/ThiagoSantosOFC/starship.git
cd starship

# Run the setup script
chmod +x setup-universal.sh
./setup-universal.sh
```

### Interactive Prompts

The script will ask you to choose:
1. **Node.js package managers** (npm, yarn, pnpm, bun)
2. **Container runtime** (Docker, Podman, or skip)
3. **Git configuration** (name and email)
4. **SSH keys** (generate or skip)

### Activate Your New Shell

```bash
# After installation completes
exec zsh
```

**That's it!** Your shell now has Zsh + Starship with the Dracula Plus theme! 🎉

## 📖 Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Get up and running in 2 minutes
- **[Complete Documentation](SETUP-UNIVERSAL-README.md)** - Full feature reference
- **[Comparison](COMPARISON.md)** - setupdev.sh vs setup-universal.sh

## 🌐 Compatibility

### ✅ Tested Distributions
- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- AlmaLinux 9
- Fedora 38+
- Rocky Linux 9
- Arch Linux
- Alpine Linux
- openSUSE Leap/Tumbleweed

### 🌍 Environments
- ✅ Native Linux
- ✅ WSL 2 (Windows Subsystem for Linux)
- ⚠️ Git Bash (Windows) - partial support

### 📦 Package Managers
- apt (Debian/Ubuntu-based)
- dnf (Fedora/RHEL-based)
- yum (Legacy RHEL)
- pacman (Arch-based)
- apk (Alpine)
- zypper (openSUSE)

## 🤖 AI-Friendly Aliases

Aliases are configured intelligently:

```bash
# In interactive shells - uses modern tools
ls      # → exa with icons
cat     # → bat with syntax highlighting

# In scripts and for AIs - uses original commands
ls      # → original ls (aliases NOT loaded)
\ls     # → always original ls (bypass alias)
```

**Benefits:**
- ✅ Scripts work normally
- ✅ AI tools aren't confused
- ✅ Original commands always accessible
- ✅ Better interactive experience

## 🔄 Idempotency

The script can be run multiple times safely:

```bash
# First run
./setup-universal.sh
# Installs everything

# Second run (after fixing issues)
./setup-universal.sh
# ✅ Skips what's already installed
# ✅ Retries what failed
# ✅ Completes missing pieces
```

## 📊 Error Reporting

The script provides detailed error reports:

```
✅ Successfully installed: 25 tools
⏭️  Skipped: 3 tools
❌ Failed: 2 tools

⚠️  Failed installations:
   ✗ pipx: Installation failed
   ✗ btop: Download error

❌ CRITICAL FAILURES DETECTED:
   ▶ starship-theme - Setup may be incomplete!
   
📝 Check log: /tmp/setup-universal-*.log
```

## 🎨 Starship Dracula Plus Theme

The repository includes a custom Starship theme (`starship.toml`) with:
- Dracula Plus color palette
- OS icon indicator
- Git branch status
- Language version displays (Node.js, Python, Go, Rust, etc.)
- Command duration
- Current time
- Username display
- Beautiful powerline-style separators

### Preview
```
╭─ ~/ 󰊢 main ────────────────────── 󰎙 Node.js v20.11.0  12:34  user 
╰─λ 
```

## 📁 Repository Structure

```
starship/
├── setup-universal.sh          # Main setup script (1,484 lines)
├── setupdev.sh                 # Original AlmaLinux-specific script
├── starship.toml               # Dracula Plus theme configuration
├── README.md                   # This file
├── QUICKSTART.md               # Quick start guide
├── SETUP-UNIVERSAL-README.md   # Complete documentation
└── COMPARISON.md               # Feature comparison
```

## 🔧 Available Commands After Setup

### System
```bash
sysinfo        # System information
cleanup        # Clean up system
update         # Update packages
```

### Git
```bash
gst            # git status
ga .           # git add .
gcm "msg"      # git commit -m "msg"
gp             # git push
gl             # git pull
lg             # lazygit (TUI)
```

### Dotfiles Management
```bash
dotfiles-backup    # Backup configurations
dotfiles-restore   # Restore configurations
dotfiles-sync      # Sync with remote repository
```

### Navigation
```bash
z <name>       # Smart cd (zoxide)
..             # cd ..
...            # cd ../..
-              # cd to previous directory
```

### Search
```bash
Ctrl+T         # Fuzzy find files
Ctrl+R         # Fuzzy find in history
Alt+C          # Fuzzy find directories
```

## 🎯 Use Cases

### For Individual Developers
- Set up a consistent development environment across multiple machines
- Quickly configure new VMs or WSL instances
- Share your exact setup with teammates

### For Teams
- Standardize development environments
- Onboard new developers faster
- Ensure everyone has the same tools

### For CI/CD
- Reproducible build environments
- Docker container initialization
- Automated testing setups

## 🛠️ Customization

### Starship Theme
```bash
# Edit theme
nvim ~/.config/starship.toml

# Apply changes
exec zsh
```

### Zsh Aliases
```bash
# Add custom aliases
nvim ~/.zshrc

# Add your aliases at the end:
# alias deploy='./scripts/deploy.sh'

# Reload
source ~/.zshrc
```

### LazyVim Plugins
```bash
# Add plugins
nvim ~/.config/nvim/lua/plugins/myplugin.lua

# Sync plugins
:Lazy sync
```

## 🐛 Troubleshooting

### Command not found after installation
```bash
# Reload shell
exec zsh

# Or manually source
source ~/.zshrc
```

### Rust/cargo not found
```bash
source ~/.cargo/env
```

### Node/npm not found
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use --lts
```

### Icons not showing
1. Install a Nerd Font on your system
2. Configure your terminal to use it:
   - **Windows Terminal**: Settings → Profiles → Font face
   - **iTerm2**: Preferences → Profiles → Text → Font
   - **Alacritty**: Edit `alacritty.yml`

### Script stopped or failed
```bash
# Check logs
cat /tmp/setup-universal-*.log

# Run again (idempotent - safe!)
./setup-universal.sh
```

## 📝 Logs

Each run generates a detailed log:
```bash
# Location
/tmp/setup-universal-YYYYMMDD-HHMMSS.log

# View in real-time
tail -f /tmp/setup-universal-*.log

# Search for errors
grep -i error /tmp/setup-universal-*.log
```

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Areas for Contribution
- [ ] Support for more package managers (e.g., homebrew on Linux)
- [ ] Additional themes for Starship
- [ ] More dotfiles templates
- [ ] Windows PowerShell support
- [ ] Additional language support (Ruby, PHP, etc.)
- [ ] Integration tests

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Thiago Santos**
- GitHub: [@ThiagoSantosOFC](https://github.com/ThiagoSantosOFC)
- Email: thiago.santos@doutorvida.pt

## 🙏 Acknowledgments

- [Starship](https://starship.rs/) - Fast, customizable prompt
- [Dracula Theme](https://draculatheme.com/) - Beautiful color palette
- [LazyVim](https://www.lazyvim.org/) - Neovim configuration
- All the amazing open-source tools included in this setup

## ⭐ Star History

If this project helped you, please consider giving it a star! ⭐

## 📈 Project Stats

- **Lines of Code**: ~1,500 in main script
- **Supported Distros**: 20+
- **Tools Installed**: 25+
- **Languages**: 5
- **Documentation**: 2,600+ lines

## 🚦 Status

- ✅ Stable and production-ready
- ✅ Actively maintained
- ✅ Tested on multiple distributions
- ✅ Comprehensive error handling
- ✅ Full idempotency support

## 📬 Support

If you need help or have questions:

1. Check the [Quick Start Guide](QUICKSTART.md)
2. Read the [Complete Documentation](SETUP-UNIVERSAL-README.md)
3. Search [existing issues](https://github.com/ThiagoSantosOFC/starship/issues)
4. Open a [new issue](https://github.com/ThiagoSantosOFC/starship/issues/new)

## 🗺️ Roadmap

- [ ] macOS support
- [ ] Windows PowerShell native support
- [ ] Web-based configuration wizard
- [ ] Docker image for testing
- [ ] Automated CI/CD testing across distros
- [ ] Plugin system for custom tools
- [ ] Configuration profiles (minimal, full, custom)

---

<div align="center">

**Made with ❤️ for developers who love beautiful, functional terminals**

[⬆ Back to Top](#-universal-development-environment-setup)

</div>

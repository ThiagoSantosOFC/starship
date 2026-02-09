#!/bin/bash

# ============================================================================
# 🚀 Universal Development Environment Setup Script
# ============================================================================
# Description: Intelligent setup script for any Linux distro (WSL/native) + Git Bash
# Features:
#   - Universal package manager detection (apt/dnf/pacman/apk/zypper)
#   - Idempotent: safe to run multiple times
#   - Modular: clean separation of concerns
#   - Stable: robust error handling and logging
#   - AI-friendly aliases: don't break script behavior
# ============================================================================

set -o pipefail  # Fail on pipe errors but continue on single command failures

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/setup-universal-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"

# Environment detection
OS_TYPE=""
DISTRO_NAME=""
PACKAGE_MANAGER=""
IS_WSL=false
IS_GIT_BASH=false
ARCH=""

# Installation flags
INSTALLED_TOOLS=()
FAILED_TOOLS=()
SKIPPED_TOOLS=()
CRITICAL_FAILURES=()
ERROR_MESSAGES=()

# ============================================================================
# COLOR CODES
# ============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' BOLD='' DIM='' NC=''
fi

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_init() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Setup Universal Log - $(date) ===" > "$LOG_FILE"
    echo "Script version: $SCRIPT_VERSION" >> "$LOG_FILE"
}

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[✓]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[✗]${NC} $1"
}

log_skip() {
    log "${CYAN}[SKIP]${NC} $1"
    SKIPPED_TOOLS+=("$2")
}

log_critical_failure() {
    log "${RED}${BOLD}[CRITICAL FAILURE]${NC} $1"
    CRITICAL_FAILURES+=("$2")
    ERROR_MESSAGES+=("$2: $1")
}

track_failure() {
    local tool="$1"
    local error_msg="$2"
    local is_critical="${3:-false}"
    
    FAILED_TOOLS+=("$tool")
    ERROR_MESSAGES+=("$tool: $error_msg")
    
    if [[ "$is_critical" == "true" ]]; then
        CRITICAL_FAILURES+=("$tool")
    fi
}

log_step() {
    log "\n${PURPLE}${BOLD}[STEP]${NC} $1"
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_substep() {
    log "  ${DIM}→${NC} $1"
}

# ============================================================================
# PROGRESS INDICATOR FUNCTIONS
# ============================================================================

# Show a spinner while a command runs
show_progress() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC} %s\r" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    # Clear the line
    printf "\r%*s\r" $(tput cols) ""
}

# Run a command with a progress indicator
run_with_progress() {
    local message="$1"
    local estimated_time="$2"
    shift 2
    local cmd="$@"
    
    log_substep "$message (may take $estimated_time)..."
    
    # Run command in background and show progress
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local cmd_pid=$!
    
    show_progress $cmd_pid "$message"
    
    # Wait for command to finish and get exit code
    wait $cmd_pid
    return $?
}

# Run cargo install with visual feedback (cargo builds are VERY slow)
cargo_install_with_progress() {
    local crate_name="$1"
    local bin_name="$2"
    
    if command_exists "$bin_name"; then
        log_skip "$bin_name already installed" "$bin_name"
        return 0
    fi
    
    log_substep "Installing $crate_name (compiling from source: ~5-10 min)..."
    echo -e "  ${YELLOW}⏳ Compiling Rust code - this is slow but happens only once${NC}"
    
    cargo install "$crate_name" >> "$LOG_FILE" 2>&1 &
    local cargo_pid=$!
    
    show_progress $cargo_pid "Compiling $crate_name"
    
    wait $cargo_pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "$bin_name installed"
        INSTALLED_TOOLS+=("$bin_name")
        return 0
    else
        log_warning "Failed to install $crate_name (see $LOG_FILE)"
        FAILED_TOOLS+=("$bin_name")
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

command_exists() {
    command -v "$1" &>/dev/null
}

has_sudo() {
    if command_exists sudo && sudo -n true 2>/dev/null; then
        return 0
    elif [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

run_sudo() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
        log_substep "Backed up: $file"
    fi
}

# ============================================================================
# ENVIRONMENT DETECTION
# ============================================================================

detect_os() {
    log_step "Detecting environment"
    
    # Detect WSL
    if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
        IS_WSL=true
        log_info "Running in WSL"
    fi
    
    # Detect Git Bash (Windows)
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        IS_GIT_BASH=true
        log_info "Running in Git Bash (Windows)"
        OS_TYPE="windows"
        return
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    log_info "Architecture: $ARCH"
    
    # Detect Linux distribution
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE="linux"
        DISTRO_NAME="${ID:-unknown}"
        log_info "Distribution: ${NAME:-unknown} ${VERSION:-}"
    else
        log_warning "Cannot detect Linux distribution"
        OS_TYPE="linux"
        DISTRO_NAME="unknown"
    fi
}

detect_package_manager() {
    log_substep "Detecting package manager..."
    
    if command_exists apt-get; then
        PACKAGE_MANAGER="apt"
        log_info "Package manager: apt (Debian/Ubuntu-based)"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
        log_info "Package manager: dnf (Fedora/RHEL-based)"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
        log_info "Package manager: yum (Legacy RHEL-based)"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        log_info "Package manager: pacman (Arch-based)"
    elif command_exists apk; then
        PACKAGE_MANAGER="apk"
        log_info "Package manager: apk (Alpine-based)"
    elif command_exists zypper; then
        PACKAGE_MANAGER="zypper"
        log_info "Package manager: zypper (openSUSE)"
    else
        PACKAGE_MANAGER="none"
        log_warning "No package manager detected - will use manual installation methods"
    fi
}

check_prerequisites() {
    log_substep "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root!"
        log_info "Run as normal user. Script will ask for sudo when needed."
        exit 1
    fi
    
    # Check sudo access (skip for Git Bash)
    if [[ "$IS_GIT_BASH" == false ]] && ! $IS_WSL; then
        if ! has_sudo; then
            log_warning "No sudo access detected. Some features may not work."
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
        else
            log_success "Sudo access verified"
        fi
    fi
    
    # Check basic tools
    for tool in curl wget git; do
        if ! command_exists "$tool"; then
            log_warning "$tool not found - will attempt to install"
        fi
    done
}

print_environment_summary() {
    log_step "Environment Summary"
    log "  OS Type: ${BOLD}$OS_TYPE${NC}"
    log "  Distribution: ${BOLD}$DISTRO_NAME${NC}"
    log "  Package Manager: ${BOLD}$PACKAGE_MANAGER${NC}"
    log "  Architecture: ${BOLD}$ARCH${NC}"
    log "  WSL: ${BOLD}$IS_WSL${NC}"
    log "  Git Bash: ${BOLD}$IS_GIT_BASH${NC}"
}

# ============================================================================
# PACKAGE MANAGER ABSTRACTION
# ============================================================================

pkg_update() {
    log_substep "Updating package lists..."
    case "$PACKAGE_MANAGER" in
        apt)
            run_sudo apt-get update -y ;;
        dnf|yum)
            run_sudo $PACKAGE_MANAGER check-update || true ;;
        pacman)
            run_sudo pacman -Sy ;;
        apk)
            run_sudo apk update ;;
        zypper)
            run_sudo zypper refresh ;;
        *)
            log_skip "No package manager to update" "pkg_update"
            ;;
    esac
}

pkg_install() {
    local packages=("$@")
    
    # Show what we're installing
    log_substep "Installing: ${packages[*]}"
    
    case "$PACKAGE_MANAGER" in
        apt)
            run_sudo apt-get install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE" | grep -E "(Setting up|Unpacking|Processing|Reading)" || true
            ;;
        dnf|yum)
            run_sudo $PACKAGE_MANAGER install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE" | grep -E "(Installing|Complete)" || true
            ;;
        pacman)
            run_sudo pacman -S --noconfirm "${packages[@]}" 2>&1 | tee -a "$LOG_FILE" | grep -E "(installing|upgrading)" || true
            ;;
        apk)
            run_sudo apk add "${packages[@]}" 2>&1 | tee -a "$LOG_FILE" | grep -E "(Installing|OK)" || true
            ;;
        zypper)
            run_sudo zypper install -y "${packages[@]}" 2>&1 | tee -a "$LOG_FILE" | grep -E "(Installing|retrieving)" || true
            ;;
        *)
            log_warning "Cannot install packages without package manager"
            return 1
            ;;
    esac
}

# ============================================================================
# SYSTEM BASE SETUP
# ============================================================================

setup_base_system() {
    log_step "Setting up base system"
    
    if [[ "$IS_GIT_BASH" == true ]]; then
        log_skip "Skipping system setup on Git Bash" "base_system"
        return 0
    fi
    
    # Update system
    pkg_update
    
    # Install essential tools
    log_substep "Installing essential tools..."
    local essential_tools=()
    
    case "$PACKAGE_MANAGER" in
        apt)
            essential_tools=(build-essential curl wget git unzip tar gzip ca-certificates)
            ;;
        dnf|yum)
            pkg_install epel-release || true
            run_sudo $PACKAGE_MANAGER groupinstall -y "Development Tools" || true
            essential_tools=(curl wget git unzip tar gzip ca-certificates)
            ;;
        pacman)
            essential_tools=(base-devel curl wget git unzip tar gzip ca-certificates)
            ;;
        apk)
            essential_tools=(build-base curl wget git unzip tar gzip ca-certificates)
            ;;
        zypper)
            essential_tools=(patterns-devel-base-devel_basis curl wget git unzip tar gzip ca-certificates)
            ;;
    esac
    
    if [[ ${#essential_tools[@]} -gt 0 ]]; then
        pkg_install "${essential_tools[@]}" 2>&1 | tee -a "$LOG_FILE" || log_warning "Some essential tools failed to install"
    fi
    
    # Enable additional repos (RHEL-based)
    if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
        log_substep "Enabling PowerTools/CRB repository..."
        run_sudo dnf config-manager --set-enabled crb 2>/dev/null || \
        run_sudo dnf config-manager --set-enabled powertools 2>/dev/null || \
        log_warning "Could not enable PowerTools/CRB"
    fi
    
    log_success "Base system setup complete"
}

# ============================================================================
# RUST INSTALLATION
# ============================================================================

install_rust() {
    log_step "Installing Rust"
    
    if command_exists cargo && command_exists rustc; then
        local rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
        log_skip "Rust already installed ($rust_version)" "rust"
        return 0
    fi
    
    if run_with_progress "Installing Rust via rustup" "~2-3 min" \
        "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"; then
        # Source cargo env
        source "$HOME/.cargo/env" 2>/dev/null || true
        log_success "Rust installed successfully"
        INSTALLED_TOOLS+=("rust")
    else
        log_error "Failed to install Rust"
        FAILED_TOOLS+=("rust")
        return 1
    fi
}

# ============================================================================
# NODE.JS INSTALLATION
# ============================================================================

install_nodejs() {
    log_step "Installing Node.js"
    
    if command_exists node && command_exists npm; then
        local node_version=$(node --version 2>/dev/null)
        log_skip "Node.js already installed ($node_version)" "nodejs"
        return 0
    fi
    
    log_substep "Installing Node.js via nvm..."
    
    # Install nvm
    if [[ ! -d "$HOME/.nvm" ]]; then
        if run_with_progress "Installing nvm" "~30 sec" \
            "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"; then
            :
        else
            log_error "Failed to install nvm"
            FAILED_TOOLS+=("nodejs")
            return 1
        fi
    fi
    
    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node.js LTS
    if command_exists nvm; then
        if run_with_progress "Installing Node.js LTS" "~2-3 min" \
            "nvm install --lts && nvm use --lts"; then
            log_success "Node.js installed successfully"
            INSTALLED_TOOLS+=("nodejs")
        else
            log_error "Failed to install Node.js"
            FAILED_TOOLS+=("nodejs")
            return 1
        fi
    else
        log_error "nvm not available after installation"
        FAILED_TOOLS+=("nodejs")
        return 1
    fi
}

# ============================================================================
# PYTHON INSTALLATION
# ============================================================================

install_python() {
    log_step "Installing Python"
    
    if command_exists python3; then
        local python_version=$(python3 --version 2>/dev/null)
        log_skip "Python already installed ($python_version)" "python"
    else
        log_substep "Installing Python..."
        case "$PACKAGE_MANAGER" in
            apt)
                pkg_install python3 python3-pip python3-venv ;;
            dnf|yum)
                pkg_install python3 python3-pip ;;
            pacman)
                pkg_install python python-pip ;;
            apk)
                pkg_install python3 py3-pip ;;
            zypper)
                pkg_install python3 python3-pip ;;
        esac
        log_success "Python installed"
        INSTALLED_TOOLS+=("python")
    fi
    
    # Install pipx
    if command_exists pipx; then
        log_skip "pipx already installed" "pipx"
    else
        if run_with_progress "Installing pipx" "~30 sec" \
            "python3 -m pip install --user pipx && python3 -m pipx ensurepath"; then
            log_success "pipx installed"
            INSTALLED_TOOLS+=("pipx")
        else
            log_warning "pipx installation failed (non-critical)"
            FAILED_TOOLS+=("pipx")
        fi
    fi
}

# ============================================================================
# GO INSTALLATION
# ============================================================================

install_go() {
    log_step "Installing Go"
    
    if command_exists go; then
        local go_version=$(go version 2>/dev/null | awk '{print $3}')
        log_skip "Go already installed ($go_version)" "go"
        return 0
    fi
    
    log_substep "Installing Go..."
    local GO_VERSION="1.22.0"
    local GO_TARBALL="go${GO_VERSION}.linux-${ARCH}.tar.gz"
    local GO_URL="https://go.dev/dl/${GO_TARBALL}"
    
    # Adjust arch name
    if [[ "$ARCH" == "x86_64" ]]; then
        GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TARBALL}"
    elif [[ "$ARCH" == "aarch64" ]]; then
        GO_TARBALL="go${GO_VERSION}.linux-arm64.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TARBALL}"
    fi
    
    cd /tmp
    if run_with_progress "Downloading Go ${GO_VERSION}" "~1-2 min" \
        "wget -q '$GO_URL'"; then
        log_substep "Extracting Go to /usr/local..."
        run_sudo rm -rf /usr/local/go
        run_sudo tar -C /usr/local -xzf "$GO_TARBALL" >> "$LOG_FILE" 2>&1
        rm -f "$GO_TARBALL"
        
        # Add to PATH
        export PATH=$PATH:/usr/local/go/bin
        
        log_success "Go installed successfully"
        INSTALLED_TOOLS+=("go")
    else
        log_error "Failed to download Go"
        FAILED_TOOLS+=("go")
        return 1
    fi
}

# ============================================================================
# C/C++ TOOLS INSTALLATION
# ============================================================================

install_c_tools() {
    log_step "Installing C/C++ Development Tools"
    
    if command_exists gcc && command_exists g++; then
        local gcc_version=$(gcc --version 2>/dev/null | head -n1)
        log_skip "GCC already installed ($gcc_version)" "gcc"
        return 0
    fi
    
    log_substep "Installing C/C++ compiler and tools..."
    case "$PACKAGE_MANAGER" in
        apt)
            pkg_install build-essential gcc g++ make cmake ;;
        dnf|yum)
            pkg_install gcc gcc-c++ make cmake ;;
        pacman)
            pkg_install gcc make cmake ;;
        apk)
            pkg_install gcc g++ make cmake ;;
        zypper)
            pkg_install gcc gcc-c++ make cmake ;;
    esac
    
    log_success "C/C++ tools installed"
    INSTALLED_TOOLS+=("gcc")
}

# ============================================================================
# MODERN CLI TOOLS INSTALLATION
# ============================================================================

install_modern_cli_tools() {
    log_step "Installing modern CLI tools"
    
    # Source cargo env if available
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    
    # Tools available via package manager
    log_substep "Installing tools via package manager..."
    local pm_tools=()
    
    case "$PACKAGE_MANAGER" in
        apt)
            pm_tools=(htop tree jq tmux vim-nox nano net-tools lsof)
            ;;
        dnf|yum)
            pm_tools=(htop tree jq tmux vim-enhanced nano net-tools lsof)
            ;;
        pacman)
            pm_tools=(htop tree jq tmux vim nano net-tools lsof)
            ;;
        apk)
            pm_tools=(htop tree jq tmux vim nano net-tools lsof)
            ;;
        zypper)
            pm_tools=(htop tree jq tmux vim nano net-tools lsof)
            ;;
    esac
    
    if [[ ${#pm_tools[@]} -gt 0 ]]; then
        pkg_install "${pm_tools[@]}" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    # Install neofetch if available
    if ! command_exists neofetch; then
        pkg_install neofetch 2>/dev/null || log_substep "neofetch not available in repos"
    fi
    
    # Tools via Cargo (Rust)
    if command_exists cargo; then
        log_substep "Installing Rust-based CLI tools (each takes ~5-10 min to compile)..."
        echo -e "  ${YELLOW}💡 Tip: Rust tools compile from source = slow but powerful!${NC}"
        
        local rust_tools=(
            "bat:bat"                    # cat with syntax highlighting
            "exa:exa"                    # modern ls
            "fd-find:fd"                 # modern find
            "ripgrep:rg"                 # fast grep
            "du-dust:dust"               # modern du
            "zoxide:zoxide"              # smart cd
            "starship:starship"          # customizable prompt
            "dua-cli:dua"                # disk usage analyzer
        )
        
        for tool_spec in "${rust_tools[@]}"; do
            local crate_name="${tool_spec%%:*}"
            local bin_name="${tool_spec##*:}"
            
            cargo_install_with_progress "$crate_name" "$bin_name"
        done
    else
        log_warning "Cargo not found - skipping Rust-based tools"
    fi
    
    log_success "Modern CLI tools installation complete"
}

# ============================================================================
# EXTRA TOOLS INSTALLATION
# ============================================================================

install_extra_tools() {
    log_step "Installing extra tools"
    
    # fzf
    if command_exists fzf; then
        log_skip "fzf already installed" "fzf"
    else
        if [[ ! -d ~/.fzf ]]; then
            if run_with_progress "Installing fzf" "~30 sec" \
                "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all"; then
                log_success "fzf installed"
                INSTALLED_TOOLS+=("fzf")
            else
                log_warning "Failed to install fzf"
                FAILED_TOOLS+=("fzf")
            fi
        fi
    fi
    
    # btop
    if command_exists btop; then
        log_skip "btop already installed" "btop"
    else
        local btop_url="https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz"
        if run_with_progress "Downloading and installing btop" "~30 sec" \
            "curl -sL '$btop_url' | tar -xj -C /tmp"; then
            run_sudo mkdir -p /usr/local/bin
            run_sudo mv /tmp/btop/bin/btop /usr/local/bin/ 2>/dev/null || true
            run_sudo chmod +x /usr/local/bin/btop
            log_success "btop installed"
            INSTALLED_TOOLS+=("btop")
        else
            log_warning "Failed to install btop"
            FAILED_TOOLS+=("btop")
        fi
    fi
    
    # tldr (via npm if available)
    if command_exists tldr; then
        log_skip "tldr already installed" "tldr"
    elif command_exists npm; then
        if run_with_progress "Installing tldr" "~30 sec" \
            "npm install -g tldr"; then
            log_success "tldr installed"
            INSTALLED_TOOLS+=("tldr")
        else
            log_warning "Failed to install tldr"
        fi
    fi
    
    # lazygit
    if command_exists lazygit; then
        log_skip "lazygit already installed" "lazygit"
    else
        log_substep "Getting lazygit latest version..."
        local lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        if [[ -n "$lazygit_version" ]]; then
            if run_with_progress "Installing lazygit v${lazygit_version}" "~30 sec" \
                "curl -sLo /tmp/lazygit.tar.gz 'https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version}_Linux_x86_64.tar.gz' && run_sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit && rm -f /tmp/lazygit.tar.gz"; then
                log_success "lazygit installed"
                INSTALLED_TOOLS+=("lazygit")
            else
                log_warning "Failed to install lazygit"
                FAILED_TOOLS+=("lazygit")
            fi
        else
            log_warning "Failed to get lazygit version"
            FAILED_TOOLS+=("lazygit")
        fi
    fi
    
    # delta (git diff)
    if command_exists delta; then
        log_skip "delta already installed" "delta"
    else
        log_substep "Getting delta latest version..."
        local delta_version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ -n "$delta_version" ]]; then
            if run_with_progress "Installing delta ${delta_version}" "~30 sec" \
                "curl -sLo /tmp/delta.tar.gz 'https://github.com/dandavison/delta/releases/latest/download/delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz' && tar xf /tmp/delta.tar.gz -C /tmp && run_sudo mv /tmp/delta-*/delta /usr/local/bin/ 2>/dev/null && rm -rf /tmp/delta*"; then
                log_success "delta installed"
                INSTALLED_TOOLS+=("delta")
            else
                log_warning "Failed to install delta"
                FAILED_TOOLS+=("delta")
            fi
        else
            log_warning "Failed to get delta version"
            FAILED_TOOLS+=("delta")
        fi
    fi
    
    log_success "Extra tools installation complete"
}

# ============================================================================
# NODE.JS PACKAGE MANAGERS (bun, pnpm, yarn)
# ============================================================================

install_node_package_managers() {
    log_step "Installing Node.js package managers"
    
    if ! command_exists npm; then
        log_warning "npm not found - skipping package managers"
        return 1
    fi
    
    echo -e "\n${YELLOW}Which Node.js package managers would you like to install?${NC}"
    echo "1) npm only (already installed)"
    echo "2) npm + yarn"
    echo "3) npm + pnpm"
    echo "4) npm + bun"
    echo "5) All (npm + yarn + pnpm + bun)"
    echo "6) Skip"
    
    read -p "Choose option (1-6): " pm_choice
    
    case "$pm_choice" in
        1)
            log_info "Using npm only"
            ;;
        2)
            run_with_progress "Installing yarn" "~30 sec" \
                "npm install -g yarn" && \
                log_success "yarn installed" || log_warning "yarn installation failed"
            ;;
        3)
            run_with_progress "Installing pnpm" "~30 sec" \
                "npm install -g pnpm" && \
                log_success "pnpm installed" || log_warning "pnpm installation failed"
            ;;
        4)
            if run_with_progress "Installing bun" "~1 min" \
                "curl -fsSL https://bun.sh/install | bash"; then
                export PATH="$HOME/.bun/bin:$PATH"
                log_success "bun installed"
            else
                log_warning "bun installation failed"
            fi
            ;;
        5)
            log_substep "Installing all package managers..."
            run_with_progress "Installing yarn and pnpm" "~1 min" \
                "npm install -g yarn pnpm"
            run_with_progress "Installing bun" "~1 min" \
                "curl -fsSL https://bun.sh/install | bash"
            export PATH="$HOME/.bun/bin:$PATH"
            log_success "All package managers installed"
            ;;
        *)
            log_skip "Skipping additional package managers" "node_pm"
            ;;
    esac
}

# ============================================================================
# DOCKER/PODMAN INSTALLATION
# ============================================================================

install_containers() {
    log_step "Container Runtime Installation"
    
    if command_exists docker || command_exists podman; then
        log_skip "Container runtime already installed" "containers"
        return 0
    fi
    
    echo -e "\n${YELLOW}Which container runtime would you like to install?${NC}"
    echo "1) Docker Engine (native)"
    echo "2) Use Docker Desktop (Windows/WSL integration)"
    echo "3) Podman (Docker alternative)"
    echo "4) Skip"
    
    read -p "Choose option (1-4): " container_choice
    
    case "$container_choice" in
        1)
            log_substep "Installing Docker Engine..."
            case "$PACKAGE_MANAGER" in
                apt)
                    # Docker official repo for Ubuntu/Debian
                    run_sudo apt-get remove docker docker-engine docker.io containerd runc 2>/dev/null || true
                    run_sudo apt-get install -y ca-certificates curl gnupg
                    run_sudo install -m 0755 -d /etc/apt/keyrings
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | run_sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                    run_sudo apt-get update
                    run_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                    ;;
                dnf|yum)
                    run_sudo $PACKAGE_MANAGER install -y dnf-plugins-core
                    run_sudo $PACKAGE_MANAGER config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    run_sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                    run_sudo systemctl enable --now docker
                    ;;
                *)
                    log_warning "Docker installation not supported for $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            run_sudo usermod -aG docker $USER || true
            log_success "Docker installed - logout/login to use without sudo"
            INSTALLED_TOOLS+=("docker")
            ;;
        2)
            log_info "Using Docker Desktop from Windows"
            log_info "Make sure Docker Desktop has WSL integration enabled"
            ;;
        3)
            log_substep "Installing Podman..."
            pkg_install podman
            log_success "Podman installed"
            INSTALLED_TOOLS+=("podman")
            ;;
        *)
            log_skip "Skipping container runtime" "containers"
            ;;
    esac
}

# ============================================================================
# NERD FONTS INSTALLATION
# ============================================================================

install_nerd_fonts() {
    log_step "Installing Nerd Fonts"
    
    local fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"
    
    local fonts=(
        "FiraCode:FiraCode"
        "JetBrainsMono:JetBrainsMono"
    )
    
    for font_spec in "${fonts[@]}"; do
        local font_name="${font_spec%%:*}"
        local font_file="${font_spec##*:}"
        
        if ls "$fonts_dir" | grep -qi "$font_file" 2>/dev/null; then
            log_skip "$font_name Nerd Font already installed" "$font_name"
            continue
        fi
        
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_file}.zip"
        
        if run_with_progress "Downloading $font_name Nerd Font" "~1-2 min" \
            "wget -q '$font_url' -O '/tmp/${font_file}.zip' && unzip -qo '/tmp/${font_file}.zip' -d '$fonts_dir' && rm -f '/tmp/${font_file}.zip'"; then
            log_success "$font_name Nerd Font installed"
        else
            log_warning "Failed to install $font_name Nerd Font"
        fi
    done
    
    # Refresh font cache
    if command_exists fc-cache; then
        fc-cache -fv >> "$LOG_FILE" 2>&1
        log_success "Font cache refreshed"
    fi
    
    if [[ "$IS_WSL" == true ]]; then
        log_info "WSL detected: Configure Windows Terminal to use a Nerd Font"
        log_info "Settings -> Profiles -> Defaults -> Appearance -> Font face"
    fi
}

# ============================================================================
# LAZYVIM INSTALLATION
# ============================================================================

install_lazyvim() {
    log_step "Installing LazyVim"
    
    # Install Neovim
    if command_exists nvim; then
        local nvim_version=$(nvim --version 2>/dev/null | head -n1)
        log_skip "Neovim already installed ($nvim_version)" "neovim"
    else
        log_substep "Installing Neovim..."
        case "$PACKAGE_MANAGER" in
            apt)
                # Use PPA for latest version
                run_sudo add-apt-repository ppa:neovim-ppa/unstable -y 2>/dev/null || true
                pkg_update
                pkg_install neovim
                ;;
            dnf|yum)
                pkg_install neovim python3-neovim
                ;;
            pacman)
                pkg_install neovim
                ;;
            *)
                # Fallback: download AppImage
                log_substep "Installing Neovim AppImage..."
                wget -q https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -O /tmp/nvim.appimage
                chmod +x /tmp/nvim.appimage
                run_sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
                ;;
        esac
        log_success "Neovim installed"
        INSTALLED_TOOLS+=("neovim")
    fi
    
    # Backup existing Neovim config
    if [[ -d ~/.config/nvim ]]; then
        backup_file ~/.config/nvim
        log_substep "Backed up existing nvim config"
    fi
    
    # Install LazyVim
    if run_with_progress "Cloning LazyVim starter config" "~30 sec" \
        "git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git"; then
        log_success "LazyVim installed - run 'nvim' to complete setup"
    else
        log_warning "Failed to clone LazyVim"
        FAILED_TOOLS+=("lazyvim")
    fi
}

# ============================================================================
# ZSH INSTALLATION AND CONFIGURATION
# ============================================================================

install_zsh() {
    log_step "Installing and configuring Zsh"
    
    # Install Zsh
    if ! command_exists zsh; then
        log_substep "Installing Zsh..."
        if ! pkg_install zsh; then
            log_critical_failure "Failed to install Zsh" "zsh"
            track_failure "zsh" "Package installation failed" "true"
            return 1
        fi
        log_success "Zsh installed"
        INSTALLED_TOOLS+=("zsh")
    else
        log_skip "Zsh already installed" "zsh"
    fi
    
    # Install Zsh plugins
    log_substep "Installing Zsh plugins..."
    mkdir -p ~/.zsh
    
    # zsh-autosuggestions
    if [[ ! -d ~/.zsh/zsh-autosuggestions ]]; then
        if run_with_progress "Installing zsh-autosuggestions" "~10 sec" \
            "git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions"; then
            :
        else
            log_warning "Failed to install zsh-autosuggestions"
            track_failure "zsh-autosuggestions" "Git clone failed" "false"
        fi
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d ~/.zsh/zsh-syntax-highlighting ]]; then
        if run_with_progress "Installing zsh-syntax-highlighting" "~10 sec" \
            "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting"; then
            :
        else
            log_warning "Failed to install zsh-syntax-highlighting"
            track_failure "zsh-syntax-highlighting" "Git clone failed" "false"
        fi
    fi
    
    # zsh-completions
    if [[ ! -d ~/.zsh/zsh-completions ]]; then
        if run_with_progress "Installing zsh-completions" "~10 sec" \
            "git clone https://github.com/zsh-users/zsh-completions ~/.zsh/zsh-completions"; then
            :
        else
            log_warning "Failed to install zsh-completions"
            track_failure "zsh-completions" "Git clone failed" "false"
        fi
    fi
    
    log_success "Zsh plugins installed"
}

configure_zsh() {
    log_step "Configuring Zsh"
    
    backup_file ~/.zshrc
    
    # Create .zshrc with AI-friendly aliases
    cat > ~/.zshrc << 'ZSHRC_EOF'
# ============================================================================
# 🎨 Universal Zsh Configuration - AI-friendly
# ============================================================================

# Only use aliases in interactive shells (don't break scripts/AI tools)
if [[ $- == *i* ]]; then
    # Starship prompt
    eval "$(starship init zsh)"
    
    # Initialize modern tools FIRST (before aliases)
    # zoxide: smart cd alternative (use 'z' command, NOT cd)
    if command -v zoxide &>/dev/null; then
        eval "$(zoxide init zsh --no-cmd)"
        # Create 'z' alias manually (don't override cd)
        alias z='__zoxide_z'
        alias zi='__zoxide_zi'
    fi
    
    # FZF initialization (correct way)
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    
    # FZF configuration
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null || find . -type f'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null || find . -type d'
    
    # AI-FRIENDLY ALIASES: Original commands always available via \command
    # Modern alternatives (only in interactive mode)
    if command -v bat &>/dev/null; then
        alias cat='bat'
    fi
    if command -v exa &>/dev/null; then
        alias ls='exa --icons'
        alias ll='exa -l --icons'
        alias la='exa -la --icons'
        alias tree='exa --tree --icons'
    else
        alias ls='ls --color=auto'
        alias ll='ls -la --color=auto'
        alias la='ls -la --color=auto'
    fi
    if command -v fd &>/dev/null; then
        alias find='fd'
    fi
    if command -v rg &>/dev/null; then
        alias grep='rg'
    fi
    if command -v dust &>/dev/null; then
        alias du='dust'
    fi
    if command -v tldr &>/dev/null; then
        alias help='tldr'
    fi
    if command -v btop &>/dev/null; then
        alias top='btop'
    elif command -v htop &>/dev/null; then
        alias top='htop'
    fi
    
    # Traditional navigation
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias ~='cd ~'
    alias -- -='cd -'
    alias c='clear'
    alias h='history'
    alias j='jobs -l'
    
    # Git aliases
    alias g='git'
    alias ga='git add'
    alias gaa='git add --all'
    alias gc='git commit -v'
    alias gca='git commit -v -a'
    alias gcm='git commit -m'
    alias gco='git checkout'
    alias gd='git diff'
    alias gl='git pull'
    alias gp='git push'
    alias gst='git status'
    alias glog='git log --oneline --decorate --graph'
    alias lg='lazygit 2>/dev/null || git log --graph --pretty=format:"%h -%d %s (%cr) <%an>" --abbrev-commit'
    
    # System aliases
    alias ports='netstat -tulanp'
    alias meminfo='free -m -l -t'
    alias ps='ps auxf'
    alias psg='ps aux | grep -v grep | grep -i -E'
    alias myip='curl http://ipecho.net/plain; echo'
    alias logs='sudo journalctl -f'
    
    # Package manager aliases (distro-agnostic)
    if command -v apt-get &>/dev/null; then
        alias update='sudo apt-get update && sudo apt-get upgrade'
        alias install='sudo apt-get install'
        alias search='apt-cache search'
    elif command -v dnf &>/dev/null; then
        alias update='sudo dnf update'
        alias install='sudo dnf install'
        alias search='dnf search'
    elif command -v pacman &>/dev/null; then
        alias update='sudo pacman -Syu'
        alias install='sudo pacman -S'
        alias search='pacman -Ss'
    fi
fi

# History configuration (works in all modes)
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

# Completions
autoload -U compinit
compinit -d ~/.zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Load plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || true
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || true
fpath=(~/.zsh/zsh-completions/src $fpath)

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Useful functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

backup() {
    cp "$1"{,.bak}
}

# PATH optimization
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.bun/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Cargo env
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
ZSHRC_EOF
    
    log_success "Zsh configured with AI-friendly aliases"
}

configure_starship() {
    log_step "Configuring Starship"
    
    # Check if starship is installed
    if ! command_exists starship; then
        log_critical_failure "Starship not installed - cannot configure theme" "starship-config"
        track_failure "starship-config" "Starship binary not found" "true"
        return 1
    fi
    
    mkdir -p ~/.config
    backup_file ~/.config/starship.toml
    
    # Copy the existing starship.toml from the repo
    if [[ -f "$SCRIPT_DIR/starship.toml" ]]; then
        if cp "$SCRIPT_DIR/starship.toml" ~/.config/starship.toml 2>> "$LOG_FILE"; then
            log_success "Starship configured with Dracula Plus theme"
            INSTALLED_TOOLS+=("starship-theme")
        else
            log_critical_failure "Failed to copy starship.toml" "starship-theme"
            track_failure "starship-theme" "Failed to copy config file" "true"
            return 1
        fi
    else
        log_critical_failure "starship.toml not found in $SCRIPT_DIR" "starship-theme"
        track_failure "starship-theme" "Config file missing from repo" "true"
        log_warning "Using default Starship configuration instead"
        return 1
    fi
}

set_default_shell() {
    log_step "Setting Zsh as default shell"
    
    local current_shell=$(basename "$SHELL")
    if [[ "$current_shell" == "zsh" ]]; then
        log_skip "Zsh already default shell" "default_shell"
        return 0
    fi
    
    local zsh_path=$(which zsh)
    
    # Try chsh first
    if run_sudo chsh -s "$zsh_path" "$USER" >> "$LOG_FILE" 2>&1; then
        log_success "Zsh set as default shell via chsh"
        log_info "Restart your terminal or run: exec zsh"
        return 0
    fi
    
    # If chsh fails (common in WSL), add auto-exec to .bashrc
    log_warning "chsh failed, adding auto-launch to .bashrc instead"
    
    if [[ -f ~/.bashrc ]] && ! grep -q "exec zsh" ~/.bashrc; then
        backup_file ~/.bashrc
        cat >> ~/.bashrc << 'BASHRC_ZSH'

# Auto-launch Zsh (added by setup-universal.sh)
if [[ -x /usr/bin/zsh ]] && [[ "$SHELL" != */zsh ]]; then
    export SHELL=$(which zsh)
    exec zsh
fi
BASHRC_ZSH
        log_success "Added Zsh auto-launch to ~/.bashrc"
        log_info "Restart your terminal or run: exec zsh"
    else
        log_info "Zsh auto-launch already in ~/.bashrc"
    fi
}

# ============================================================================
# GIT CONFIGURATION
# ============================================================================

configure_git() {
    log_step "Configuring Git"
    
    # Get current git config
    local current_name=$(git config --global user.name 2>/dev/null)
    local current_email=$(git config --global user.email 2>/dev/null)
    
    if [[ -n "$current_name" && -n "$current_email" ]]; then
        log_info "Current Git config: $current_name <$current_email>"
        read -p "Update Git configuration? (y/n): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
    fi
    
    # Interactive Git configuration
    read -p "Enter your full name: " git_name
    read -p "Enter your email: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Configure delta if installed
    if command_exists delta; then
        log_substep "Configuring delta for git diff..."
        git config --global core.pager delta
        git config --global interactive.diffFilter 'delta --color-only'
        git config --global delta.navigate true
        git config --global delta.light false
        git config --global delta.side-by-side true
    fi
    
    # Useful git aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.visual 'log --graph --oneline --decorate --all'
    
    log_success "Git configured successfully"
}

# ============================================================================
# SSH KEY GENERATION
# ============================================================================

setup_ssh_keys() {
    log_step "SSH Key Setup"
    
    if [[ -f ~/.ssh/id_ed25519 || -f ~/.ssh/id_rsa ]]; then
        log_info "SSH keys already exist"
        read -p "Generate new SSH key? (y/n): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
    fi
    
    read -p "Generate SSH key (ED25519)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter email for SSH key: " ssh_email
        
        ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519 -N ""
        
        eval "$(ssh-agent -s)" >> "$LOG_FILE" 2>&1
        ssh-add ~/.ssh/id_ed25519 >> "$LOG_FILE" 2>&1
        
        log_success "SSH key generated!"
        log_info "Public key:"
        cat ~/.ssh/id_ed25519.pub
        echo
        log_info "Add this key to GitHub/GitLab/Bitbucket"
    fi
}

# ============================================================================
# DOTFILES BACKUP SYSTEM
# ============================================================================

setup_dotfiles() {
    log_step "Setting up dotfiles management"
    
    local dotfiles_dir="$HOME/dotfiles"
    
    if [[ -d "$dotfiles_dir/.git" ]]; then
        log_skip "Dotfiles repo already exists" "dotfiles"
        return 0
    fi
    
    mkdir -p "$dotfiles_dir"
    cd "$dotfiles_dir"
    
    git init >> "$LOG_FILE" 2>&1
    
    # Create dotfiles structure
    mkdir -p "$dotfiles_dir/.config"
    
    # Copy current configs
    [[ -f ~/.zshrc ]] && cp ~/.zshrc "$dotfiles_dir/.zshrc"
    [[ -f ~/.config/starship.toml ]] && cp ~/.config/starship.toml "$dotfiles_dir/.config/starship.toml"
    [[ -f ~/.gitconfig ]] && cp ~/.gitconfig "$dotfiles_dir/.gitconfig"
    
    # Create README
    cat > "$dotfiles_dir/README.md" << 'EOF'
# My Dotfiles

Managed by setup-universal.sh

## Usage

```bash
# Backup current configs
dotfiles-backup

# Restore configs
dotfiles-restore

# Sync to remote
dotfiles-sync
```
EOF
    
    # Create helper scripts
    mkdir -p ~/.local/bin
    
    cat > ~/.local/bin/dotfiles-backup << 'EOF'
#!/bin/bash
cd ~/dotfiles
cp ~/.zshrc .zshrc 2>/dev/null
cp ~/.config/starship.toml .config/starship.toml 2>/dev/null
cp ~/.gitconfig .gitconfig 2>/dev/null
git add -A
git commit -m "Backup $(date +%Y-%m-%d\ %H:%M:%S)"
echo "✅ Dotfiles backed up"
EOF
    
    cat > ~/.local/bin/dotfiles-restore << 'EOF'
#!/bin/bash
cd ~/dotfiles
[[ -f .zshrc ]] && cp .zshrc ~/.zshrc
[[ -f .config/starship.toml ]] && mkdir -p ~/.config && cp .config/starship.toml ~/.config/starship.toml
[[ -f .gitconfig ]] && cp .gitconfig ~/.gitconfig
echo "✅ Dotfiles restored"
EOF
    
    cat > ~/.local/bin/dotfiles-sync << 'EOF'
#!/bin/bash
cd ~/dotfiles
if git remote get-url origin &>/dev/null; then
    git pull --rebase
    git push
    echo "✅ Dotfiles synced"
else
    echo "⚠️  No remote configured. Add with: git remote add origin <url>"
fi
EOF
    
    chmod +x ~/.local/bin/dotfiles-*
    
    log_success "Dotfiles management setup complete"
    log_info "Commands: dotfiles-backup, dotfiles-restore, dotfiles-sync"
}

# ============================================================================
# UTILITY SCRIPTS
# ============================================================================

create_utility_scripts() {
    log_step "Creating utility scripts"
    
    mkdir -p ~/.local/bin
    
    # System info script
    cat > ~/.local/bin/sysinfo << 'EOF'
#!/bin/bash
echo "🎨 ==================== SYSTEM INFO ===================="
echo "🖥️  OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -s)"
echo "💻 Hostname: $(hostname)"
echo "👤 User: $(whoami)"
echo "📅 Date: $(date)"
echo "⏰ Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "💾 Memory: $(free -h 2>/dev/null | awk 'NR==2{printf "%s/%s (%.1f%%)\n", $3,$2,$3*100/$2}' || echo 'N/A')"
echo "💿 Disk: $(df -h / 2>/dev/null | awk 'NR==2{printf "%s/%s (%s used)\n", $3,$2,$5}' || echo 'N/A')"
echo "====================================================="
EOF
    
    # Cleanup script
    cat > ~/.local/bin/cleanup << 'EOF'
#!/bin/bash
echo "🧹 Cleaning system..."
if command -v apt-get &>/dev/null; then
    sudo apt-get autoremove -y
    sudo apt-get autoclean
elif command -v dnf &>/dev/null; then
    sudo dnf clean all
    sudo journalctl --vacuum-time=7d
elif command -v pacman &>/dev/null; then
    sudo pacman -Sc --noconfirm
fi
rm -rf ~/.cache/thumbnails/* 2>/dev/null
echo "✅ Cleanup complete!"
EOF
    
    chmod +x ~/.local/bin/sysinfo
    chmod +x ~/.local/bin/cleanup
    
    log_success "Utility scripts created"
}

# ============================================================================
# POST-INSTALLATION VERIFICATION
# ============================================================================

verify_installation() {
    log_step "Verifying installation"
    
    local tools_to_verify=(
        "git:Git"
        "curl:cURL"
        "cargo:Rust"
        "node:Node.js"
        "npm:npm"
        "python3:Python"
        "go:Go"
        "gcc:GCC"
        "zsh:Zsh"
        "starship:Starship"
        "nvim:Neovim"
    )
    
    local verified=0
    local total=${#tools_to_verify[@]}
    
    for tool_spec in "${tools_to_verify[@]}"; do
        local cmd="${tool_spec%%:*}"
        local name="${tool_spec##*:}"
        
        if command_exists "$cmd"; then
            log_success "$name: ✓"
            ((verified++))
        else
            log_warning "$name: ✗"
        fi
    done
    
    log_info "Verified: $verified/$total tools"
}

# ============================================================================
# CONFIG-ONLY MODE
# ============================================================================

apply_configs_only() {
    log_init
    
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║           🔧 APPLY CONFIGURATIONS ONLY (NO INSTALLS)                  ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_step "Applying configurations without reinstalling tools"
    
    # Only apply configs
    configure_starship || log_warning "Starship configuration had issues"
    configure_zsh || log_warning "Zsh configuration had issues"
    set_default_shell || log_warning "Setting default shell had issues"
    
    log_step "Configuration Complete!"
    echo
    log "${GREEN}${BOLD}✅ Configurations applied successfully${NC}"
    echo
    log "${YELLOW}${BOLD}Next steps:${NC}"
    log "  1. Reload your shell: ${BOLD}exec zsh${NC}"
    log "  2. Verify: ${BOLD}echo \$SHELL${NC}"
    echo
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    log_init
    
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║        🚀 UNIVERSAL DEVELOPMENT ENVIRONMENT SETUP v${SCRIPT_VERSION}          ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Environment detection
    detect_os
    detect_package_manager
    check_prerequisites
    print_environment_summary
    
    echo -e "\n${YELLOW}${BOLD}This script will install:${NC}"
    echo "  • Languages: Rust, Node.js (nvm), Python, Go, C/C++"
    echo "  • Package Managers: npm, yarn/pnpm/bun (your choice)"
    echo "  • Modern CLI: bat, exa, fd, ripgrep, dust, zoxide, fzf, btop, lazygit, delta"
    echo "  • Containers: Docker/Podman (optional)"
    echo "  • Editor: LazyVim (Neovim)"
    echo "  • Shell: Zsh + plugins + Starship (Dracula Plus theme)"
    echo "  • Fonts: Nerd Fonts (FiraCode, JetBrainsMono)"
    echo "  • Tools: Git config, SSH keys, dotfiles management"
    echo
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read
    
    # Run installations (continue even if one fails)
    setup_base_system || log_warning "Base system setup had issues"
    install_rust || log_warning "Rust installation had issues"
    install_nodejs || log_warning "Node.js installation had issues"
    install_node_package_managers || log_warning "Node package managers had issues"
    install_python || log_warning "Python installation had issues"
    install_go || log_warning "Go installation had issues"
    install_c_tools || log_warning "C/C++ tools installation had issues"
    install_modern_cli_tools || log_warning "Modern CLI tools had issues"
    install_extra_tools || log_warning "Extra tools installation had issues"
    install_containers || log_warning "Container installation had issues"
    install_nerd_fonts || log_warning "Nerd fonts installation had issues"
    install_lazyvim || log_warning "LazyVim installation had issues"
    install_zsh || log_warning "Zsh installation had issues"
    configure_starship || log_warning "Starship configuration had issues"
    configure_zsh || log_warning "Zsh configuration had issues"
    set_default_shell || log_warning "Setting default shell had issues"
    configure_git || log_warning "Git configuration had issues"
    setup_ssh_keys || log_warning "SSH keys setup had issues"
    setup_dotfiles || log_warning "Dotfiles setup had issues"
    create_utility_scripts || log_warning "Utility scripts creation had issues"
    verify_installation || log_warning "Verification had issues"
    
    # Final summary
    log_step "Installation Complete!"
    echo
    log "${GREEN}${BOLD}✅ Successfully installed: ${#INSTALLED_TOOLS[@]} tools${NC}"
    log "${CYAN}⏭️  Skipped: ${#SKIPPED_TOOLS[@]} tools${NC}"
    log "${RED}❌ Failed: ${#FAILED_TOOLS[@]} tools${NC}"
    echo
    
    # Check if failed tools list needs attention
    if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
        log "${YELLOW}${BOLD}⚠️  Failed installations:${NC}"
        for i in "${!FAILED_TOOLS[@]}"; do
            local tool="${FAILED_TOOLS[$i]}"
            local error="${ERROR_MESSAGES[$i]:-Unknown error}"
            log "   ${RED}✗${NC} $error"
        done
        echo
        log "${YELLOW}Check detailed log: ${LOG_FILE}${NC}"
        echo
    fi
    
    # Check critical failures
    if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
        log "${RED}${BOLD}❌ CRITICAL FAILURES DETECTED:${NC}"
        for critical in "${CRITICAL_FAILURES[@]}"; do
            log "   ${RED}▶${NC} $critical - Setup may be incomplete!"
        done
        echo
        log "${RED}${BOLD}CRITICAL COMPONENTS THAT FAILED:${NC}"
        if [[ " ${CRITICAL_FAILURES[*]} " =~ " zsh " ]]; then
            log "   ${RED}✗ Zsh${NC} - Shell installation failed"
        fi
        if [[ " ${CRITICAL_FAILURES[*]} " =~ " starship " ]] || [[ " ${CRITICAL_FAILURES[*]} " =~ " starship-config " ]] || [[ " ${CRITICAL_FAILURES[*]} " =~ " starship-theme " ]]; then
            log "   ${RED}✗ Starship / Dracula Plus Theme${NC} - Prompt configuration failed"
        fi
        if [[ " ${CRITICAL_FAILURES[*]} " =~ " zsh-config " ]]; then
            log "   ${RED}✗ Zsh Configuration${NC} - Shell config failed"
        fi
        echo
        log "${YELLOW}${BOLD}⚠️  You may need to manually install critical components${NC}"
        log "${YELLOW}   Check the log file for error details: ${LOG_FILE}${NC}"
        echo
    fi
    
    log "${PURPLE}${BOLD}📋 IMPORTANT - Next Steps:${NC}"
    log ""
    log "  ${BOLD}${YELLOW}⚠️  CRITICAL: Activate Zsh + Starship now:${NC}"
    log "     ${GREEN}exec zsh${NC}"
    log ""
    log "  ${DIM}(This will reload your shell with Zsh and apply Starship Dracula Plus theme)${NC}"
    log ""
    log "  After running 'exec zsh', you can:"
    log "  2. Run ${BOLD}sysinfo${NC} to see system information"
    log "  3. Run ${BOLD}cleanup${NC} to clean up system"
    log "  4. Configure ${BOLD}dotfiles remote${NC}: cd ~/dotfiles && git remote add origin <url>"
    log "  5. Open ${BOLD}nvim${NC} to complete LazyVim setup"
    echo
    log "${CYAN}📝 Log file: ${LOG_FILE}${NC}"
    echo
    
    # Show what shell is active
    local current_shell=$(basename "$SHELL")
    if [[ "$current_shell" == "zsh" ]]; then
        log "${GREEN}${BOLD}✅ Zsh is your default shell!${NC}"
        log "${GREEN}   Run 'exec zsh' to apply Starship theme now.${NC}"
    else
        log "${YELLOW}${BOLD}⚠️  Default shell is still: $current_shell${NC}"
        log "${YELLOW}   Zsh was set as default. Run 'exec zsh' now, or logout/login.${NC}"
    fi
    echo
    
    log "${GREEN}${BOLD}🎉 Enjoy your new development environment with Starship Dracula Plus theme!${NC}"
    echo
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse command line arguments
    case "${1:-}" in
        --config-only|--configs-only|-c)
            apply_configs_only
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --config-only, -c    Apply configurations only (skip installations)"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                   # Full installation"
            echo "  $0 --config-only     # Only apply .zshrc and starship configs"
            ;;
        *)
            main "$@"
            ;;
    esac
fi


#!/bin/bash

# ============================================================================
# 🎨 Script de Shell Visual para CentOS 9
# ============================================================================
# Descrição: Transformar CentOS 9 em uma shell moderna e bonita
# Foco: Ferramentas visuais, utilitárias e experiência de usuário
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}[STEP]${NC} $1"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Verificar se está rodando como root ou com sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Este script não deve ser executado como root!"
        log_info "Execute como usuário normal. O script pedirá senha quando necessário."
        exit 1
    fi
    
    if ! sudo -v; then
        log_error "Este script requer privilégios sudo"
        exit 1
    fi
    
    log_success "Permissões verificadas - OK"
}

# Verificar distribuição
check_centos() {
    if ! grep -q "CentOS Linux 9\|Red Hat Enterprise Linux 9\|Rocky Linux 9\|AlmaLinux 9" /etc/os-release 2>/dev/null; then
        log_warning "Este script foi otimizado para CentOS 9, RHEL 9, Rocky Linux 9 ou AlmaLinux 9"
        read -p "Deseja continuar mesmo assim? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 0
        fi
    fi
    log_success "Sistema compatível detectado"
}

# Atualizar sistema e instalar repositórios
setup_repos() {
    log_step "Configurando repositórios e atualizando sistema"
    
    log_info "Atualizando sistema..."
    sudo dnf update -y
    
    log_info "Instalando EPEL..."
    sudo dnf install -y epel-release
    
    log_info "Habilitando PowerTools/CRB..."
    sudo dnf config-manager --enable crb 2>/dev/null || sudo dnf config-manager --enable powertools 2>/dev/null || true
    
    log_info "Instalando dependências básicas..."
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y curl wget git unzip tar gzip
    
    log_success "Repositórios configurados"
}

# Instalar Rust (necessário para muitas ferramentas modernas)
install_rust() {
    log_step "Instalando Rust"
    
    if command -v cargo &> /dev/null; then
        log_warning "Rust já está instalado"
        return 0
    fi
    
    log_info "Instalando Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    
    log_success "Rust instalado com sucesso"
}

# Instalar Node.js (via NodeSource)
install_nodejs() {
    log_step "Instalando Node.js"
    
    if command -v node &> /dev/null; then
        log_warning "Node.js já está instalado"
        return 0
    fi
    
    log_info "Instalando Node.js 20 LTS..."
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
    
    log_success "Node.js instalado"
}

# Instalar ferramentas CLI modernas
install_modern_tools() {
    log_step "Instalando ferramentas CLI modernas"
    
    # Ferramentas via DNF/EPEL
    log_info "Instalando ferramentas via DNF..."
    sudo dnf install -y \
        htop \
        neofetch \
        tree \
        jq \
        httpie \
        tmux \
        vim-enhanced \
        nano \
        which \
        lsof \
        net-tools
    
    # Instalar ferramentas via Cargo (Rust)
    if command -v cargo &> /dev/null; then
        log_info "Instalando ferramentas via Cargo..."
        
        # Lista de ferramentas a instalar
        local rust_tools=(
            "bat"           # cat com syntax highlighting
            "exa"           # ls moderno
            "fd-find"       # find moderno
            "ripgrep"       # grep ultrarrápido
            "dust"          # du moderno
            "zoxide"        # cd inteligente
            "starship"      # prompt customizável
            "dua-cli"       # análise interativa de disco
        )
        
        for tool in "${rust_tools[@]}"; do
            log_info "Instalando $tool..."
            cargo install $tool || log_warning "Falha ao instalar $tool"
        done
    fi
    
    log_success "Ferramentas modernas instaladas"
}

# Instalar ferramentas extras
install_extra_tools() {
    log_step "Instalando ferramentas extras"
    
    # Instalar fzf se não estiver instalado
    if [ ! -d ~/.fzf ]; then
        log_info "Instalando fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    else
        log_warning "fzf já está instalado"
    fi
    
    # Instalar btop
    log_info "Instalando btop..."
    local btop_url="https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz"
    curl -L $btop_url | tar -xj -C /tmp
    sudo mv /tmp/btop/bin/btop /usr/local/bin/
    sudo chmod +x /usr/local/bin/btop
    
    # Instalar tldr via npm
    log_info "Instalando tldr..."
    sudo npm install -g tldr
    
    # Instalar lazygit
    log_info "Instalando lazygit..."
    local lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r .tag_name)
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version#v}_Linux_x86_64.tar.gz"
    sudo tar xf lazygit.tar.gz -C /usr/local/bin lazygit
    rm lazygit.tar.gz
    
    # Instalar delta (git diff melhorado)
    log_info "Instalando delta..."
    local delta_version=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r .tag_name)
    curl -Lo delta.tar.gz "https://github.com/dandavison/delta/releases/latest/download/delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz"
    tar xf delta.tar.gz
    sudo mv delta-*/delta /usr/local/bin/
    rm -rf delta*
    
    log_success "Ferramentas extras instaladas"
}

# Instalar e configurar Zsh
install_zsh() {
    log_step "Instalando e configurando Zsh"
    
    # Instalar Zsh
    log_info "Instalando Zsh..."
    sudo dnf install -y zsh
    
    # Instalar plugins do Zsh
    log_info "Instalando plugins do Zsh..."
    
    # zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions 2>/dev/null || true
    
    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting 2>/dev/null || true
    
    # zsh-completions
    git clone https://github.com/zsh-users/zsh-completions ~/.zsh/zsh-completions 2>/dev/null || true
    
    log_success "Zsh instalado e configurado"
}

# Configurar Starship
configure_starship() {
    log_step "Configurando Starship"
    
    # Criar diretório de configuração
    mkdir -p ~/.config
    
    # Configuração do Starship com tema Dracula Plus
    cat > ~/.config/starship.toml << 'EOF'
format = """
[╭─](fg:current_line)\
$os\
$directory\
$git_branch\
$fill\
$nodejs\
$dotnet\
$python\
$java\
$c\
$cmd_duration\
$shell\
$time\
$username\
$line_break\
$character\
"""

palette = 'dracula_plus'
add_newline = true

[palettes.dracula_plus]
foreground = '#E2E2DC'
background = '#191A21'
current_line = '#282A36'
primary = '#1A1B26'
box = '#343746'
blue = '#6272A4'
cyan = '#8BE9FD'
green = '#50FA7B'
orange = '#FFB86C'
pink = '#FF79C6'
purple = '#BD93F9'
red = '#FF5555'
yellow = '#F1FA8C'

[os]
format = '[](fg:red bg:current_line)[$symbol ](fg:background bg:red)[](fg:red)'
disabled = false

[directory]
format = '[](fg:pink bg:current_line)[󰷏 ](fg:background bg:pink)[](fg:pink bg:box)[ $read_only$truncation_symbol$path](fg:foreground bg:box)[](fg:box)'
home_symbol = " ~/"
truncation_symbol = ' '
truncation_length = 2
read_only = '󱧵 '
read_only_style = ''

[git_branch]
format = '[](fg:green bg:current_line)[$symbol](fg:background bg:green)[](fg:green bg:box)[ $branch](fg:foreground bg:box)[](fg:box)'
symbol = ' '

[nodejs]
format = '[](fg:green bg:current_line)[$symbol](fg:background bg:green)[](fg:green bg:box)[ $version](fg:foreground bg:box)[](fg:box)'
symbol = '󰎙 Node.js'

[dotnet]
format = '[](fg:purple bg:current_line)[$symbol](fg:background bg:purple)[](fg:purple bg:box)[ $tfm](fg:foreground bg:box)[](fg:box)'
symbol = ' .NET'

[python]
format = '[](fg:green bg:current_line)[$symbol](fg:background bg:green)[](fg:green bg:box)[ $version](fg:foreground bg:box)[](fg:box)'
symbol = ' python'

[java]
format = '[](fg:red bg:current_line)[$symbol](fg:background bg:red)[](fg:red bg:box)[ $version](fg:foreground bg:box)[](fg:box)'
symbol = ' Java'

[c]
format = '[](fg:blue bg:current_line)[$symbol](fg:background bg:blue)[](fg:blue bg:box)[ $version](fg:foreground bg:box)[](fg:box)'
symbol = ' C'

[fill]
symbol = '─'
style = 'fg:current_line'

[cmd_duration]
min_time = 500
format = '[](fg:orange bg:current_line)[ ](fg:background bg:orange)[](fg:orange bg:box)[ $duration ](fg:foreground bg:box)[](fg:box)'

[shell]
format = '[](fg:blue bg:current_line)[ ](fg:background bg:blue)[](fg:blue bg:box)[ $indicator](fg:foreground bg:box)[](fg:box)'
unknown_indicator = 'shell'
powershell_indicator = 'powershell'
fish_indicator = 'fish'
disabled = false

[time]
format = '[](fg:purple bg:current_line)[󰦖 ](fg:background bg:purple)[](fg:purple bg:box)[ $time](fg:foreground bg:box)[](fg:box)'
time_format = '%H:%M'
disabled = false

[username]
format = '[](fg:yellow bg:current_line)[ ](fg:background bg:yellow)[](fg:yellow bg:box)[ $user](fg:foreground bg:box)[](fg:box) '
show_always = true

[character]
format = """
[╰─$symbol](fg:current_line) """
success_symbol = '[λ](fg:bold white)'
error_symbol = '[×](fg:bold red)'
EOF
    
    log_success "Starship configurado com tema Dracula Plus"
}

# Configurar Zsh como shell padrão
configure_zsh() {
    log_step "Configurando Zsh"
    
    # Criar configuração do Zsh
    cat > ~/.zshrc << 'EOF'
# ============================================================================
# 🎨 Configuração Zsh Otimizada para CentOS 9
# ============================================================================

# Starship
eval "$(starship init zsh)"

# Inicializar ferramentas modernas
eval "$(zoxide init zsh)" 2>/dev/null || true
eval "$(fzf --zsh)" 2>/dev/null || source ~/.fzf.zsh 2>/dev/null || true

# Configurar FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null || find . -type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null || find . -type d'

# Aliases modernos
alias cat='bat 2>/dev/null || cat'
alias ls='exa --icons 2>/dev/null || ls --color=auto'
alias ll='exa -l --icons 2>/dev/null || ls -la --color=auto'
alias la='exa -la --icons 2>/dev/null || ls -la --color=auto'
alias tree='exa --tree --icons 2>/dev/null || tree'
alias find='fd 2>/dev/null || find'
alias grep='rg 2>/dev/null || grep --color=auto'
alias du='dust 2>/dev/null || du -h'
alias cd='z 2>/dev/null || cd'
alias help='tldr 2>/dev/null || man'
alias top='btop 2>/dev/null || htop 2>/dev/null || top'
alias http='httpie 2>/dev/null || curl'
alias system='neofetch 2>/dev/null || uname -a'

# Aliases tradicionais
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

# Sistema aliases
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -E'
alias myip='curl http://ipecho.net/plain; echo'
alias logs='sudo journalctl -f'
alias update='sudo dnf update'
alias install='sudo dnf install'
alias search='dnf search'

# Histórico otimizado
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

# Plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || true
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || true
source ~/.zsh/zsh-completions/zsh-completions.plugin.zsh 2>/dev/null || true

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Funções úteis
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

# Informações do sistema na inicialização
if command -v neofetch &> /dev/null; then
    neofetch
else
    echo "🎨 CentOS 9 Visual Shell - Pronto!"
    echo "Usuário: $(whoami) | Host: $(hostname) | Uptime: $(uptime -p)"
fi

# PATH otimizado
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
EOF
    
    # Configurar Git com delta
    log_info "Configurando Git com delta..."
    git config --global core.pager delta 2>/dev/null || true
    git config --global interactive.diffFilter 'delta --color-only' 2>/dev/null || true
    git config --global delta.navigate true 2>/dev/null || true
    git config --global delta.light false 2>/dev/null || true
    
    log_success "Zsh configurado com plugins e aliases"
}

# Configurar shell padrão
set_default_shell() {
    log_step "Configurando Zsh como shell padrão"
    
    local current_shell=$(echo $SHELL)
    if [[ "$current_shell" == *"zsh"* ]]; then
        log_warning "Zsh já é o shell padrão"
        return 0
    fi
    
    log_info "Alterando shell padrão para Zsh..."
    sudo chsh -s $(which zsh) $USER
    
    log_success "Shell padrão alterado para Zsh"
    log_warning "Faça logout e login novamente para aplicar as mudanças"
}

# Criar scripts utilitários
create_utility_scripts() {
    log_step "Criando scripts utilitários"
    
    mkdir -p ~/.local/bin
    
    # Script para mostrar informações do sistema
    cat > ~/.local/bin/sysinfo << 'EOF'
#!/bin/bash
echo "🎨 ==================== INFORMAÇÕES DO SISTEMA ===================="
echo "🖥️  Sistema: $(hostnamectl | grep "Operating System" | cut -d: -f2 | xargs)"
echo "💻 Hostname: $(hostname)"
echo "👤 Usuário: $(whoami)"
echo "📅 Data: $(date)"
echo "⏰ Uptime: $(uptime -p)"
echo "💾 Memória: $(free -h | awk 'NR==2{printf "%.1f/%.1fGB (%.2f%%)\n", $3/1024/1024,$2/1024/1024,$3*100/$2}')"
echo "💿 Disco: $(df -h / | awk 'NR==2{printf "%s/%s (%s usado)\n", $3,$2,$5}')"
echo "🌡️  CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
echo "🔢 Cores: $(nproc) cores"
echo "📊 Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "=================================================================="
EOF
    
    # Script para limpeza do sistema
    cat > ~/.local/bin/cleanup << 'EOF'
#!/bin/bash
echo "🧹 Limpando sistema..."
sudo dnf clean all
sudo journalctl --vacuum-time=7d
rm -rf ~/.cache/thumbnails/*
echo "✅ Limpeza concluída!"
EOF
    
    # Script para backup de configurações
    cat > ~/.local/bin/backup-configs << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backup-configs-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
cp ~/.zshrc "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.config/starship.toml "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.gitconfig "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.vimrc "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup das configurações salvo em: $BACKUP_DIR"
EOF
    
    # Tornar scripts executáveis
    chmod +x ~/.local/bin/sysinfo
    chmod +x ~/.local/bin/cleanup
    chmod +x ~/.local/bin/backup-configs
    
    log_success "Scripts utilitários criados em ~/.local/bin/"
}

# Função principal
main() {
    echo -e "${CYAN}"
    echo "============================================================================"
    echo "🎨 SHELL VISUAL MODERNA PARA CENTOS 9"
    echo "============================================================================"
    echo -e "${NC}"
    echo "Este script irá instalar e configurar:"
    echo "• 🚀 Zsh com plugins e configuração otimizada"
    echo "• ⭐ Starship com tema Dracula Plus"
    echo "• 🔧 Ferramentas CLI modernas (bat, exa, fd, ripgrep, dust, etc.)"
    echo "• 🎯 fzf, btop, lazygit, delta, tldr"
    echo "• 📝 Aliases úteis e funções personalizadas"
    echo "• 🎪 Scripts utilitários (sysinfo, cleanup, backup-configs)"
    echo "• 🌈 Experiência visual melhorada"
    echo ""
    
    read -p "Deseja continuar com a instalação? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_info "Instalação cancelada pelo usuário"
        exit 0
    fi
    
    # Executar instalação
    check_permissions
    check_centos
    setup_repos
    install_rust
    install_nodejs
    install_modern_tools
    install_extra_tools
    install_zsh
    configure_starship
    configure_zsh
    create_utility_scripts
    set_default_shell
    
    echo -e "\n${GREEN}"
    echo "============================================================================"
    echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "============================================================================"
    echo -e "${NC}"
    echo "🎉 Sua shell CentOS 9 agora está moderna e bonita!"
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Faça logout e login novamente (ou execute: exec zsh)"
    echo "2. Execute 'sysinfo' para ver informações do sistema"
    echo "3. Execute 'cleanup' para limpar o sistema"
    echo "4. Execute 'backup-configs' para fazer backup das configurações"
    echo ""
    echo "🎨 Comandos úteis instalados:"
    echo "• bat (cat com cores) • exa (ls moderno) • fd (find rápido)"
    echo "• ripgrep (grep ultrarrápido) • dust (du visual) • zoxide (cd inteligente)"
    echo "• fzf (fuzzy finder) • btop (monitor de sistema) • lazygit (git visual)"
    echo "• delta (git diff melhorado) • tldr (exemplos de comandos)"
    echo ""
    echo "🌈 Aliases disponíveis:"
    echo "• ll, la (listagem moderna) • tree (árvore de diretórios)"
    echo "• system (neofetch) • lg (lazygit) • ports (portas abertas)"
    echo "• update (dnf update) • install (dnf install) • logs (journalctl)"
    echo ""
    echo "🔧 Funções úteis:"
    echo "• mkcd <dir> (criar e entrar no diretório)"
    echo "• extract <arquivo> (extrair qualquer arquivo)"
    echo "• backup <arquivo> (criar backup com .bak)"
    echo ""
    echo "🎯 Para personalizar mais:"
    echo "• Edite ~/.zshrc para aliases personalizados"
    echo "• Edite ~/.config/starship.toml para customizar o prompt"
    echo "• Explore as configurações em ~/.config/"
    echo ""
    echo "💡 Dicas:"
    echo "• Use Ctrl+R para buscar no histórico"
    echo "• Use Ctrl+T para buscar arquivos com fzf"
    echo "• Use Alt+C para navegar em diretórios com fzf"
    echo "• Digite 'z <parte_do_nome>' para navegar rapidamente"
    echo ""
    echo "🚀 Aproveite sua nova shell moderna no CentOS 9!"
    echo ""
    
    # Mostrar informações finais se neofetch estiver disponível
    if command -v neofetch &> /dev/null; then
        echo "🎨 Prévia do seu sistema:"
        neofetch --stdout | head -10
    fi
}

# Executar função principal
main "$@"

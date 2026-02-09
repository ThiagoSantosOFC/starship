# Comparação: setupdev.sh vs setup-universal.sh

## 📊 Resumo Executivo

| Característica | setupdev.sh | setup-universal.sh |
|----------------|-------------|-------------------|
| **Tamanho** | 664 linhas | 1,484 linhas |
| **Distros Suportadas** | CentOS/RHEL/AlmaLinux 9 | Todas (Ubuntu, Debian, Fedora, Arch, Alpine, openSUSE, etc.) |
| **Package Managers** | dnf apenas | apt, dnf, yum, pacman, apk, zypper |
| **Ambientes** | Linux nativo | Linux nativo + WSL + Git Bash (parcial) |
| **Idempotência** | Parcial | Completa |
| **Logging** | stdout apenas | arquivo + stdout |
| **Backups** | Não | Automático antes de modificar configs |
| **Aliases IA-friendly** | Não | Sim (não quebra scripts) |

## 🆕 Novas Funcionalidades

### Linguagens e Runtimes

#### setupdev.sh
- ✅ Rust (rustup)
- ✅ Node.js (NodeSource repo)

#### setup-universal.sh  
- ✅ Rust (rustup)
- ✅ Node.js (nvm - gerenciador de versões)
- ✅ **Python 3 + pipx**
- ✅ **Go (oficial)**
- ✅ **GCC/G++ (build tools)**

### Package Managers Node.js

#### setupdev.sh
- npm (vem com Node.js)

#### setup-universal.sh
- npm (vem com Node.js)
- **yarn** (opcional)
- **pnpm** (opcional)
- **bun** (opcional)
- **Escolha interativa do usuário**

### Ferramentas CLI

#### setupdev.sh ✅
- htop, neofetch, tree, jq, httpie, tmux, vim, nano
- bat, exa, fd-find, ripgrep, dust, zoxide, starship, dua-cli
- fzf, btop, lazygit, delta, tldr

#### setup-universal.sh ✅
- **Mesmas ferramentas**
- **Detecção inteligente** (skip se já instalado)
- **Instalação robusta** com fallbacks

### Containers

#### setupdev.sh
- ❌ Não suportado

#### setup-universal.sh
- ✅ **Docker Engine** (nativo)
- ✅ **Docker Desktop** (WSL integration)
- ✅ **Podman** (alternativa)
- ✅ **Escolha interativa**

### Editor

#### setupdev.sh
- Vim melhorado (básico)

#### setup-universal.sh
- nano
- **LazyVim completo** (Neovim)
  - LSP (Python, JS/TS, Go, Rust, C/C++)
  - Treesitter
  - Telescope
  - Neo-tree
  - Git integration

### Fontes

#### setupdev.sh
- ❌ Não incluso

#### setup-universal.sh
- ✅ **FiraCode Nerd Font**
- ✅ **JetBrainsMono Nerd Font**
- ✅ Instalação automática
- ✅ Instruções para WSL/Windows Terminal

### Shell e Prompt

#### setupdev.sh
- ✅ Zsh + plugins
- ✅ Starship (tema Dracula Plus)
- ✅ Configuração .zshrc com aliases

#### setup-universal.sh
- ✅ Zsh + plugins (mesmos)
- ✅ Starship (tema Dracula Plus **do seu repo**)
- ✅ **Configuração .zshrc IA-friendly**
  - Aliases só em modo interativo
  - Scripts/IAs usam comandos originais
  - `\comando` sempre usa original

### Git

#### setupdev.sh
- ✅ Delta configurado automaticamente
- ❌ Não pede nome/email

#### setup-universal.sh
- ✅ **Configuração interativa** (nome, email)
- ✅ Delta configurado
- ✅ **Aliases úteis** (co, br, ci, st, etc.)

### SSH

#### setupdev.sh
- ❌ Não suportado

#### setup-universal.sh
- ✅ **Geração opcional de chaves ED25519**
- ✅ Mostra chave pública
- ✅ Instruções para GitHub/GitLab

### Dotfiles

#### setupdev.sh
- Script `backup-configs` (backup local)

#### setup-universal.sh
- ✅ **Sistema completo baseado em Git**
- ✅ `dotfiles-backup` (commit local)
- ✅ `dotfiles-restore` (restaurar)
- ✅ `dotfiles-sync` (push/pull remoto)
- ✅ Estrutura organizada em ~/dotfiles/

### Scripts Utilitários

#### setupdev.sh
- sysinfo
- cleanup
- backup-configs

#### setup-universal.sh
- sysinfo (melhorado)
- cleanup (melhorado, multi-distro)
- dotfiles-backup
- dotfiles-restore
- dotfiles-sync

## 🔧 Melhorias Técnicas

### Detecção de Ambiente

#### setupdev.sh
```bash
# Verifica apenas CentOS/RHEL/Rocky/AlmaLinux
grep -q "CentOS Linux 9\|Red Hat Enterprise Linux 9..." /etc/os-release
```

#### setup-universal.sh
```bash
# Detecta:
- Qualquer distribuição Linux (/etc/os-release)
- WSL vs nativo (grep /proc/version)
- Git Bash ($OSTYPE)
- Arquitetura (uname -m)
- Package manager automático
```

### Instalação de Pacotes

#### setupdev.sh
```bash
# Hardcoded para dnf
sudo dnf install -y package
```

#### setup-universal.sh
```bash
# Abstração universal
pkg_install() {
    case "$PACKAGE_MANAGER" in
        apt) run_sudo apt-get install -y "$@" ;;
        dnf|yum) run_sudo $PACKAGE_MANAGER install -y "$@" ;;
        pacman) run_sudo pacman -S --noconfirm "$@" ;;
        apk) run_sudo apk add "$@" ;;
        zypper) run_sudo zypper install -y "$@" ;;
    esac
}
```

### Idempotência

#### setupdev.sh
```bash
# Verifica apenas algumas ferramentas
if command -v cargo &> /dev/null; then
    log_warning "Rust já está instalado"
    return 0
fi
```

#### setup-universal.sh
```bash
# TODAS as funções verificam antes de instalar
install_rust() {
    if command_exists cargo && command_exists rustc; then
        local rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
        log_skip "Rust already installed ($rust_version)" "rust"
        return 0
    fi
    # ... instalar
}

# Rastreamento completo
INSTALLED_TOOLS+=("rust")
SKIPPED_TOOLS+=("rust")
FAILED_TOOLS+=("rust")
```

### Tratamento de Erros

#### setupdev.sh
```bash
set -e  # Simples fail-on-error
```

#### setup-universal.sh
```bash
set -eo pipefail  # Fail-on-error + pipe failures

# Logging robusto
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Backup automático
backup_file() {
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
    fi
}
```

### Aliases IA-Friendly

#### setupdev.sh
```bash
# Aliases sempre ativos (podem quebrar scripts)
alias cat='bat 2>/dev/null || cat'
alias ls='exa --icons 2>/dev/null || ls --color=auto'
```

#### setup-universal.sh
```bash
# Aliases APENAS em shells interativos
if [[ $- == *i* ]]; then
    alias cat='bat 2>/dev/null || \cat'
    alias ls='exa --icons 2>/dev/null || \ls --color=auto'
fi

# Em scripts e para IAs:
# - Aliases não são carregados
# - \comando sempre usa original
# - Ferramentas funcionam normalmente
```

## 📈 Estatísticas

### Linhas de Código

- **setupdev.sh**: 664 linhas
- **setup-universal.sh**: 1,484 linhas (2.2x maior)
- **Funções adicionais**: 20+

### Cobertura

| Categoria | setupdev.sh | setup-universal.sh |
|-----------|-------------|-------------------|
| Distros | 4 | 20+ |
| Package Managers | 1 | 6 |
| Linguagens | 2 | 5 |
| Editores | 1 (básico) | 2 (completo) |
| Containers | 0 | 3 opções |
| Fontes | 0 | 2 |
| Dotfiles Sync | ❌ | ✅ |
| SSH Keys | ❌ | ✅ |

## 🎯 Casos de Uso

### setupdev.sh - Melhor para:
- ✅ CentOS/RHEL/AlmaLinux 9 especificamente
- ✅ Setup rápido e simples
- ✅ Usuários que só precisam de Rust + Node.js
- ✅ Ambiente já conhece (sem surpresas)

### setup-universal.sh - Melhor para:
- ✅ **Qualquer distribuição Linux**
- ✅ **Múltiplas máquinas com distros diferentes**
- ✅ **WSL (Windows)**
- ✅ **Replicar ambiente exato em novos sistemas**
- ✅ **Desenvolvimento full-stack** (múltiplas linguagens)
- ✅ **Teams com diferentes preferências** (Docker vs Podman, yarn vs pnpm)
- ✅ **CI/CD** (idempotência completa)
- ✅ **IAs e automação** (aliases não quebram)

## 🔄 Migração

Se você já usa `setupdev.sh` e quer migrar:

```bash
# 1. Backup das configs atuais
cp ~/.zshrc ~/.zshrc.backup
cp ~/.config/starship.toml ~/.config/starship.toml.backup

# 2. Executar setup-universal.sh
./setup-universal.sh

# 3. Será detectado que ferramentas já estão instaladas (skip automático)
# 4. Apenas novas features serão instaladas
# 5. Configs existentes serão backupadas automaticamente

# 4. Restart shell
exec zsh
```

## 💡 Recomendação

- **Use setupdev.sh** se:
  - Você usa exclusivamente AlmaLinux/CentOS/RHEL
  - Não precisa de Python/Go/LazyVim
  - Setup simples é suficiente

- **Use setup-universal.sh** se:
  - Você trabalha com múltiplas distros
  - Usa WSL
  - Precisa de ambiente completo (múltiplas linguagens)
  - Quer LazyVim/Docker/Fontes configurados automaticamente
  - Trabalha em equipe (dotfiles sync)
  - Usa IAs/automação (aliases IA-friendly)

## 📝 Conclusão

O `setup-universal.sh` é uma **evolução completa** do `setupdev.sh`:

- ✅ Mantém tudo que funciona bem
- ✅ Adiciona suporte universal
- ✅ Melhora idempotência e estabilidade
- ✅ Adiciona features essenciais (Docker, LazyVim, Dotfiles)
- ✅ Otimizado para IAs e automação

Ambos os scripts continuam disponíveis para diferentes casos de uso!

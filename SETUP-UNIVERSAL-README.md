# 🚀 Setup Universal - Universal Development Environment

> Script inteligente e idempotente para configurar ambiente de desenvolvimento completo em **qualquer distro Linux** (WSL/nativo) e até Windows com Git Bash.

## ✨ Características

- 🎯 **Universal**: Funciona em Ubuntu, Debian, Fedora, AlmaLinux, Arch, Alpine, openSUSE, etc.
- 🔄 **Idempotente**: Pode ser executado múltiplas vezes sem problemas
- 🧩 **Modular**: Separação clara de responsabilidades
- 🛡️ **Estável**: Tratamento robusto de erros e logging detalhado
- 🤖 **IA-friendly**: Aliases não quebram comportamento de scripts/ferramentas
- 🎨 **Tema Dracula Plus**: Starship personalizado incluído

## 📦 O que será instalado

### 🔧 Linguagens e Runtimes
- **Rust** (via rustup) - Sistema oficial
- **Node.js** (via nvm) - Gerenciador de versões
- **Python 3** + pipx - Ambiente isolado de pacotes
- **Go** - Linguagem Google
- **GCC/G++** - Compiladores C/C++

### 📦 Gerenciadores de Pacotes Node.js
Escolha interativa entre:
- npm (já vem com Node.js)
- yarn
- pnpm
- bun
- Todos acima

### 🎨 Ferramentas CLI Modernas
| Ferramenta | Substitui | Descrição |
|------------|-----------|-----------|
| **bat** | cat | Visualizador com syntax highlighting |
| **exa** | ls | Listagem moderna e colorida |
| **fd** | find | Busca de arquivos ultrarrápida |
| **ripgrep** | grep | Busca em texto ultrarrápida |
| **dust** | du | Análise de uso de disco visual |
| **zoxide** | cd | Navegação inteligente de diretórios |
| **starship** | prompt | Prompt customizável e rápido |
| **fzf** | - | Fuzzy finder interativo |
| **btop** | top/htop | Monitor de sistema bonito |
| **lazygit** | git | Interface TUI para Git |
| **delta** | git diff | Diff melhorado para Git |
| **tldr** | man | Exemplos práticos de comandos |

### 🐳 Containers (Opcional)
Escolha interativa:
- Docker Engine (nativo)
- Docker Desktop (WSL integration)
- Podman (alternativa ao Docker)
- Pular instalação

### 💻 Editores
- **nano** - Editor simples
- **LazyVim** - Neovim com configuração completa
  - LSP para Python, JS/TS, Go, Rust, C/C++
  - Treesitter (syntax highlighting)
  - Telescope (fuzzy finder)
  - Neo-tree (file explorer)
  - Git integration

### 🎨 Shell e Prompt
- **Zsh** - Shell moderno
- **Plugins Zsh**:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - zsh-completions
- **Starship** - Prompt com tema Dracula Plus personalizado

### 🔤 Fontes
- **FiraCode Nerd Font**
- **JetBrainsMono Nerd Font**
- Ícones completos para terminal

### 🔧 Configurações
- **Git** - Configuração interativa (nome, email, delta, aliases)
- **SSH Keys** - Geração opcional de chave ED25519
- **Dotfiles** - Sistema de backup/sync com Git

### 📝 Scripts Utilitários
- `sysinfo` - Informações do sistema
- `cleanup` - Limpeza de sistema
- `dotfiles-backup` - Backup de dotfiles
- `dotfiles-restore` - Restaurar dotfiles
- `dotfiles-sync` - Sync com repositório remoto

## 🚀 Uso

### Instalação Básica

```bash
# Clonar o repositório (ou baixar o script)
git clone https://github.com/seu-usuario/starship.git
cd starship

# Executar o script
./setup-universal.sh
```

### Modos de Uso

```bash
# Modo interativo (padrão)
./setup-universal.sh

# Em desenvolvimento: modos adicionais
# ./setup-universal.sh --auto        # Modo desatendido
# ./setup-universal.sh --dry-run     # Mostrar o que seria feito
# ./setup-universal.sh --update      # Atualizar ferramentas instaladas
```

## 🎯 Compatibilidade

### ✅ Testado em:
- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- AlmaLinux 9
- Fedora 38+
- Arch Linux
- Alpine Linux
- openSUSE Leap/Tumbleweed

### 🌐 Ambientes:
- ✅ WSL 2 (Windows Subsystem for Linux)
- ✅ Linux nativo
- ⚠️ Git Bash (Windows) - suporte parcial

### 📦 Gerenciadores de Pacotes:
- apt (Debian/Ubuntu)
- dnf (Fedora/RHEL/AlmaLinux/Rocky)
- yum (Legacy RHEL)
- pacman (Arch/Manjaro)
- apk (Alpine)
- zypper (openSUSE)

## 🤖 Aliases IA-Friendly

Os aliases são configurados de forma inteligente:

```bash
# Em shells interativos, usa ferramentas modernas:
ls    # → exa (se disponível) ou ls original

# Em scripts e para IAs, usa comandos originais:
\ls   # → sempre ls original (bypass aliases)

# Modo não-interativo (scripts) usa comandos originais automaticamente
```

### Exemplos de Aliases

```bash
# Navegação
ll    # exa -l --icons
la    # exa -la --icons
..    # cd ..
...   # cd ../..

# Ferramentas
cat   # bat (com syntax highlighting)
find  # fd (busca rápida)
grep  # ripgrep (busca ultrarrápida)
top   # btop (monitor visual)

# Git
g     # git
gst   # git status
gc    # git commit
gp    # git push
gl    # git pull
lg    # lazygit

# Sistema
update   # apt/dnf/pacman update
install  # apt/dnf/pacman install
cleanup  # script de limpeza
sysinfo  # informações do sistema
```

## 🎨 Personalização

### Starship (Prompt)

O script usa seu tema Dracula Plus existente em `starship.toml`. Para personalizar:

```bash
# Editar configuração
nvim ~/.config/starship.toml

# Aplicar mudanças (reload shell)
exec zsh
```

### Zsh

```bash
# Editar configuração
nvim ~/.zshrc

# Adicionar aliases personalizados
# Adicionar funções úteis
# Modificar PATH

# Aplicar mudanças
source ~/.zshrc
```

### LazyVim

```bash
# Primeira execução completa o setup
nvim

# Adicionar plugins
nvim ~/.config/nvim/lua/plugins/

# Ver documentação
:help LazyVim
```

## 📁 Estrutura de Arquivos

```
~/.config/
  ├── starship.toml          # Configuração Starship (Dracula Plus)
  └── nvim/                  # LazyVim config

~/.zshrc                     # Configuração Zsh com aliases IA-friendly

~/.local/bin/
  ├── sysinfo               # Script de info do sistema
  ├── cleanup               # Script de limpeza
  ├── dotfiles-backup       # Backup de dotfiles
  ├── dotfiles-restore      # Restaurar dotfiles
  └── dotfiles-sync         # Sync dotfiles com Git

~/dotfiles/                  # Repositório de dotfiles
  ├── .zshrc
  ├── .gitconfig
  ├── .config/
  │   └── starship.toml
  └── README.md
```

## 🔧 Gerenciamento de Dotfiles

### Backup

```bash
# Fazer backup das configurações atuais
dotfiles-backup
```

### Restaurar

```bash
# Restaurar configurações do backup
dotfiles-restore
```

### Sync com Git

```bash
# Configurar remote (primeira vez)
cd ~/dotfiles
git remote add origin git@github.com:seu-usuario/dotfiles.git

# Fazer backup e push
dotfiles-backup
dotfiles-sync
```

## 🔍 Detecção Inteligente

O script detecta automaticamente:

✅ Distribuição Linux  
✅ Gerenciador de pacotes  
✅ WSL vs Linux nativo vs Git Bash  
✅ Arquitetura (x86_64/aarch64)  
✅ Ferramentas já instaladas (skip automático)  
✅ Privilégios sudo  

## 📊 Logs e Troubleshooting

### Logs

Cada execução gera um log detalhado:

```bash
# Localização
/tmp/setup-universal-YYYYMMDD-HHMMSS.log

# Ver log em tempo real
tail -f /tmp/setup-universal-*.log

# Buscar erros
grep -i error /tmp/setup-universal-*.log
```

### Backups

Configurações antigas são automaticamente backup:

```bash
# Localização
~/.config-backups/YYYYMMDD-HHMMSS/

# Listar backups
ls -la ~/.config-backups/
```

### Problemas Comuns

#### Script falha no início
```bash
# Verificar permissões
chmod +x setup-universal.sh

# Verificar sudo
sudo -v
```

#### Ferramenta não encontrada após instalação
```bash
# Recarregar shell
exec zsh
# ou
source ~/.zshrc

# Verificar PATH
echo $PATH
```

#### Rust/Cargo não encontrado
```bash
# Source cargo env
source ~/.cargo/env

# Adicionar ao PATH permanentemente (já no .zshrc)
export PATH="$HOME/.cargo/bin:$PATH"
```

#### Node/npm não encontrado
```bash
# Source nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Instalar versão LTS
nvm install --lts
nvm use --lts
```

## 🔄 Idempotência

O script pode ser executado múltiplas vezes com segurança:

- ✅ Verifica se ferramenta já está instalada antes de instalar
- ✅ Faz backup de configurações existentes
- ✅ Não reinstala pacotes desnecessariamente
- ✅ Atualiza apenas o que mudou

```bash
# Executar novamente para instalar ferramentas que falharam
./setup-universal.sh

# Ou para adicionar ferramentas que você pulou antes
./setup-universal.sh
```

## 🎯 Próximos Passos Após Instalação

1. **Restart Shell**
   ```bash
   exec zsh
   ```

2. **Verificar Instalação**
   ```bash
   sysinfo
   ```

3. **Configurar Windows Terminal** (se WSL)
   - Settings → Profiles → Defaults → Appearance
   - Font face: "FiraCode Nerd Font" ou "JetBrainsMono Nerd Font"

4. **Configurar Git remoto para dotfiles**
   ```bash
   cd ~/dotfiles
   git remote add origin git@github.com:seu-usuario/dotfiles.git
   git push -u origin main
   ```

5. **Completar setup do LazyVim**
   ```bash
   nvim
   # Aguardar instalação de plugins
   ```

6. **Adicionar chave SSH ao GitHub/GitLab**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Copiar e adicionar em: Settings → SSH Keys
   ```

## 🤝 Contribuindo

Sugestões e melhorias são bem-vindas!

## 📝 Licença

MIT

## 👤 Autor

Criado com base na sua configuração existente (`setupdev.sh` e `starship.toml`)

---

**Nota**: Este script foi projetado para ser:
- 🧠 Inteligente: detecta ambiente automaticamente
- 🔒 Seguro: backups automáticos, idempotente
- 🚀 Rápido: skip de ferramentas já instaladas
- 🤖 IA-friendly: aliases não quebram scripts/ferramentas
- 🎨 Bonito: tema Dracula Plus personalizado

Aproveite seu novo ambiente de desenvolvimento! 🎉

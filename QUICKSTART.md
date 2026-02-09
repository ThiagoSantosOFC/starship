# 🚀 Quick Start Guide - Setup Universal

## ⚡ Instalação Rápida (2 minutos)

```bash
# 1. Clonar repositório
git clone <seu-repo-url>
cd starship

# 2. Executar script
chmod +x setup-universal.sh
./setup-universal.sh

# 3. Restart shell
exec zsh

# 4. Pronto! 🎉
```

## 📋 Checklist Durante Instalação

O script vai perguntar:

### ✅ Node.js Package Managers
```
Escolha: 1-6
Recomendado: 5 (Todos) ou 3 (npm + pnpm)
```

### ✅ Container Runtime
```
Escolha: 1-4
WSL: Opção 2 (Docker Desktop integration)
Nativo: Opção 1 (Docker Engine)
```

### ✅ Git Configuration
```
Digite seu nome completo
Digite seu email
```

### ✅ SSH Keys
```
Gerar chave? y/n
Se sim, digite email para a chave
```

## 🎯 Após Instalação (5 minutos)

### 1. Configurar Windows Terminal (se WSL)

**Abrir Windows Terminal Settings (Ctrl+,)**

```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "FiraCode Nerd Font"
      }
    }
  }
}
```

### 2. Testar Ferramentas

```bash
# Ver info do sistema
sysinfo

# Testar aliases modernos
ls        # → exa com ícones
cat file  # → bat com syntax highlighting
top       # → btop visual

# Testar git
gst       # → git status
lg        # → lazygit

# Busca fuzzy
Ctrl+T    # buscar arquivos
Ctrl+R    # buscar no histórico
Alt+C     # navegar diretórios
```

### 3. Configurar Dotfiles Remote

```bash
cd ~/dotfiles
git remote add origin git@github.com:seu-usuario/dotfiles.git
git branch -M main
git push -u origin main

# Agora use:
dotfiles-backup  # fazer backup
dotfiles-sync    # sync com GitHub
```

### 4. Setup LazyVim

```bash
# Primeira execução instala plugins
nvim

# Aguardar downloads (~2 minutos)
# Fechar e reabrir

# Comandos úteis:
# :Lazy         - gerenciar plugins
# :Mason        - gerenciar LSPs
# Space+e       - file explorer
# Space+ff      - find files
# Space+sg      - search grep
```

### 5. Adicionar SSH Key ao GitHub

```bash
# Copiar chave pública
cat ~/.ssh/id_ed25519.pub

# Ir para: https://github.com/settings/keys
# Clicar "New SSH key"
# Colar a chave
# Salvar

# Testar
ssh -T git@github.com
```

## 🔧 Troubleshooting Rápido

### Comando não encontrado após instalação

```bash
# Recarregar shell
exec zsh

# Ou
source ~/.zshrc
```

### Rust/cargo não encontrado

```bash
source ~/.cargo/env
```

### Node/npm não encontrado

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use --lts
```

### Ícones não aparecem no terminal

1. Instale uma Nerd Font no Windows
2. Configure Windows Terminal para usar a fonte
3. Restart terminal

### Docker não funciona sem sudo

```bash
# Logout e login novamente (necessário para grupo docker)
# Ou execute:
newgrp docker
```

## 📚 Comandos Essenciais

### Sistema
```bash
sysinfo      # info do sistema
cleanup      # limpar sistema
update       # atualizar pacotes
```

### Git
```bash
gst          # git status
ga .         # git add .
gcm "msg"    # git commit -m
gp           # git push
gl           # git pull
lg           # lazygit (interface visual)
```

### Dotfiles
```bash
dotfiles-backup    # backup configs
dotfiles-restore   # restaurar configs
dotfiles-sync      # sync com remoto
```

### Navegação
```bash
z <nome>     # cd inteligente (zoxide)
..           # cd ..
...          # cd ../..
-            # cd para diretório anterior
```

### Busca
```bash
Ctrl+T       # fuzzy find files
Ctrl+R       # fuzzy find history
Alt+C        # fuzzy find directories
```

## 🎨 Personalização

### Starship Prompt

```bash
nvim ~/.config/starship.toml
# Editar cores, módulos, formato
# Salvar e reload: exec zsh
```

### Aliases

```bash
nvim ~/.zshrc
# Adicionar seus aliases no fim
# Exemplo:
# alias deploy='./scripts/deploy.sh'

source ~/.zshrc
```

### LazyVim Plugins

```bash
# Criar arquivo de plugin
nvim ~/.config/nvim/lua/plugins/myplugin.lua

# Exemplo:
return {
  "plugin/name",
  config = function()
    -- config aqui
  end
}

# Salvar e :Lazy sync
```

## 🌟 Atalhos Úteis

### Terminal (Zsh)
```bash
Ctrl+A       # início da linha
Ctrl+E       # fim da linha
Ctrl+U       # apagar linha
Ctrl+K       # apagar até fim
Ctrl+W       # apagar palavra anterior
Ctrl+L       # limpar tela (ou 'c')
```

### LazyVim (Neovim)
```bash
Space+e      # toggle file explorer
Space+ff     # find files
Space+sg     # search grep
Space+/      # toggle comment
gcc          # toggle line comment
gbc          # toggle block comment
:Lazy        # plugin manager
:Mason       # LSP manager
```

### Git (lazygit)
```bash
lg           # abrir lazygit
j/k          # navegar
enter        # expandir
space        # stage/unstage
c            # commit
P            # push
p            # pull
```

## 📦 Estrutura de Arquivos Importantes

```
~/
├── .zshrc                          # config Zsh
├── .config/
│   ├── starship.toml              # config Starship
│   └── nvim/                      # config LazyVim
├── .local/bin/
│   ├── sysinfo                    # scripts
│   ├── cleanup
│   ├── dotfiles-backup
│   ├── dotfiles-restore
│   └── dotfiles-sync
├── dotfiles/                      # repo dotfiles
│   ├── .zshrc
│   ├── .gitconfig
│   └── .config/starship.toml
└── .config-backups/               # backups automáticos
```

## 🆘 Ajuda

### Ver logs de instalação
```bash
ls -lt /tmp/setup-universal-*.log
cat /tmp/setup-universal-*.log | less
```

### Reinstalar algo específico
```bash
# O script detecta o que já está instalado
# Para reinstalar, remova a ferramenta primeiro:
cargo uninstall starship
# Depois execute o script novamente
./setup-universal.sh
```

### Reverter configurações
```bash
# Backups automáticos em:
ls ~/.config-backups/

# Restaurar:
cp ~/.config-backups/YYYYMMDD-HHMMSS/.zshrc ~/.zshrc
```

## 💡 Dicas Pro

1. **Use `z` em vez de `cd`** - aprende seus diretórios mais usados
   ```bash
   z proj  # pula para ~/projects ou ~/workspace/project
   ```

2. **Ctrl+R para buscar comandos anteriores** - muito mais rápido que `history | grep`

3. **Use `bat` para preview** - syntax highlighting automático
   ```bash
   bat file.js
   ```

4. **`lg` para Git visual** - interface TUI completa

5. **Aliases não quebram scripts** - use `\comando` para original
   ```bash
   ls      # usa exa
   \ls     # usa ls original
   ```

6. **Dotfiles sync** - sempre faça backup antes de mudanças grandes
   ```bash
   dotfiles-backup
   # fazer mudanças
   dotfiles-sync
   ```

## 🎯 Próximos Passos

1. ✅ Explorar LazyVim (`:Tutor` para tutorial)
2. ✅ Configurar dotfiles remote
3. ✅ Personalizar aliases em ~/.zshrc
4. ✅ Adicionar plugins do LazyVim
5. ✅ Configurar projetos com Docker/Podman
6. ✅ Setup CI/CD com dotfiles sync

---

**Problemas?** Verifique:
- Logs: `/tmp/setup-universal-*.log`
- Documentação completa: `SETUP-UNIVERSAL-README.md`
- Comparação com setupdev.sh: `COMPARISON.md`

**Aproveite seu novo ambiente de desenvolvimento! 🚀**

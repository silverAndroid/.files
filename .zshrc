if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Load Oh My Posh
eval "$(oh-my-posh init zsh --config ~/.omp.yaml)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down
bindkey '^[w' kill-region
bindkey '[C' forward-word
bindkey '[D' backward-word
bindkey "^U" backward-kill-line
bindkey "^X^_" redo

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias c='clear'

# Check if a command exists
command_exists() {
    command=$1
    if command -v &>/dev/null; then
        return true
    else
        return false
    fi
}

# Shell integrations
if ! command_exists fzf; then
    echo "Installing fzf..."
    /opt/homebrew/bin/brew install fzf
fi
source <(fzf --zsh)
if ! command_exists zoxide; then
    echo "Installing zoxide..."
    /opt/homebrew/bin/brew install zoxide
fi
eval "$(zoxide init --cmd cd zsh)"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# nvm
export NVM_DIR="$HOME/.nvm"

if ! command_exists nvm; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun
if ! command_exists bun; then
    echo "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
fi
# bun completions
[ -s "/Users/ruru/.bun/_bun" ] && source "/Users/ruru/.bun/_bun"

# bun   
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# flutter
if ! command_exists flutter; then
    echo "Flutter is not installed. Please install it manually and add it to your PATH"
fi
export PATH=$PATH:/Users/ruru/Documents/dev/flutter

# rbenv
if ! command_exists rbenv; then
    echo "Installing rbenv..."
    /opt/homebrew/bin/brew install rbenv
fi
eval "$(rbenv init - zsh)"

FPATH=~/.rbenv/completions:"$FPATH"

# cargo
if ! command_exists cargo; then
    echo "Cargo is not installed. Please install it manually and add it to your PATH"
fi
. "$HOME/.cargo/env"

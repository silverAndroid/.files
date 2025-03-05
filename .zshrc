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

# Shell integrations
if ! command -v fzf > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install fzf
  fi
fi
source <(fzf --zsh)
if ! command -v zoxide > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install zoxide
  fi
fi
eval "$(zoxide init --cmd cd zsh)"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# nvm
if ! command -v nvm > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install nvm
  else
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash -s -- 's/(.*)//g;s/\s+$//g;s/(.*)//g' | tr -d '\r' >> /dev/null 2>&1
    bash -s -- 'echo -ne "nvm install script failed."'
  fi
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun
if ! command -v bun > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install bun
  else
    echo "Installing bun..."
    curl -o- https://bun.sh/install | bash -s -- 's/(.*)//g;s/\s+$//g;s/(.*)//g' | tr -d '\r' >> /dev/null 2>&1
    bash -s -- 'echo -ne "bun install script failed."'
  fi
fi
# bun completions
[ -s "/Users/ruru/.bun/_bun" ] && source "/Users/ruru/.bun/_bun"

# bun   
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# flutter
if ! command -v flutter > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install flutter
  else
    echo "Installing flutter..."
    curl -o- https://docs.flutter.dev/get-started/install/ | bash -s -- 's/(.*)//g;s/\s+$//g;s/(.*)//g' | tr -d '\r' >> /dev/null 2>&1
    bash -s -- 'echo -ne "flutter install script failed."'
  fi
fi
export PATH=$PATH:/Users/ruru/Documents/dev/flutter

# rbenv
if ! command -v rbenv > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install rbenv
  else
    echo "Installing rbenv..."
    curl -o- https://github.com/rbenv/rbenv-build | bash -s -- 's/(.*)//g;s/\s+$//g;s/(.*)//g' | tr -d '\r' >> /dev/null 2>&1
    bash -s -- 'echo -ne "rbenv install script failed."'
  fi
fi
eval "$(rbenv init - zsh)"

FPATH=~/.rbenv/completions:"$FPATH"

# cargo
if ! command -v cargo > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install cargo
  else
    echo "Installing cargo..."
    curl -o- https://doc.rust-lang.org/cargo/getting-started.html | bash -s -- 's/(.*)//g;s/\s+$//g;s/(.*)//g' | tr -d '\r' >> /dev/null 2>&1
    bash -s -- 'echo -ne "cargo install script failed."'
  fi
fi
. "$HOME/.cargo/env"

# Bazelisk
if ! command -v bazel > /dev/null; then
  if [[ -f "/opt/homebrew/bin/brew" ]] then
    /opt/homebrew/bin/brew install bazelisk
  fi
  if ! command -v bazel > /dev/null; then
      curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-1.18.0.tar.gz -o /tmp/bazelisk-1.18.0.tar.gz
      tar -xf /tmp/bazelisk-1.18.0.tar.gz
      chmod +x /tmp/bazelisk-1.18.0
      mv /tmp/bazelisk-1.18.0 "$HOME/bin/bazelisk"
      rm /tmp/bazelisk-1.18.0.tar.gz
      echo "Bazelisk installed successfully!"
  fi
  export PATH="$HOME/bin/bazelisk:$PATH"
fi
# --- Determine Brew Command and Setup Environment ---
BREW_CMD=""
if command -v brew > /dev/null; then
  BREW_CMD="brew"
elif [[ -f "/opt/homebrew/bin/brew" ]]; then
  BREW_CMD="/opt/homebrew/bin/brew"
elif [[ -f "/usr/local/bin/brew" ]]; then
  BREW_CMD="/usr/local/bin/brew"
elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  BREW_CMD="/home/linuxbrew/.linuxbrew/bin/brew"
fi

if [[ -n "$BREW_CMD" ]]; then
  eval "$($BREW_CMD shellenv)"
fi
# --- End Brew Command and Setup Environment ---

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
export PATH=$PATH:$(brew --prefix)/bin
export PATH=$PATH:/home/ruru/.local/bin

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# If oh-my-posh is now available (either initially or after installation), initialize it
OH_MY_POSH_CMD="oh-my-posh"
if [[ -f "$HOME/.local/bin/oh-my-posh" ]]; then
  OH_MY_POSH_CMD="$HOME/.local/bin/oh-my-posh"
fi
eval "$($OH_MY_POSH_CMD init zsh --config ~/.omp.yaml)"

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
  if command -v brew > /dev/null; then
    brew install fzf
  fi
fi
# Ensure fzf is sourced only if available
if command -v fzf > /dev/null; then
  source <(fzf --zsh)
fi

if ! command -v zoxide > /dev/null; then
  if command -v brew > /dev/null; then
    brew install zoxide
  fi
fi
# Ensure zoxide is initialized only if available
if command -v zoxide > /dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi

if command -v brew > /dev/null; then
  (nohup brew update > /dev/null) &
  (nohup brew upgrade > /dev/null) &
fi

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/28.0.13004108
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm
if ! command -v nvm > /dev/null; then
  if command -v brew > /dev/null; then
    brew install nvm
  else
    echo "Installing nvm via curl..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
fi

# java
if command -v brew > /dev/null && brew list openjdk@23 > /dev/null 2>&1; then
  # If openjdk@23 is installed via brew, set JAVA_HOME to its prefix
  export JAVA_HOME=$(brew --prefix openjdk@23)
  export PATH=$JAVA_HOME/bin:$PATH
elif [[ -d "/opt/homebrew/opt/openjdk@23" ]]; then # Fallback for existing manual Mac M1/M2 setups
  export JAVA_HOME=/opt/homebrew/opt/openjdk@23
  export PATH=$JAVA_HOME/bin:$PATH
fi


# Bazelisk
if ! command -v bazel > /dev/null; then
  if command -v brew > /dev/null; then
    brew install bazelisk
  fi
  if ! command -v bazel > /dev/null; then # If brew install failed or brew is not available
      echo "Installing Bazelisk via curl..."
      curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-1.18.0.tar.gz -o /tmp/bazelisk-1.18.0.tar.gz
      tar -xf /tmp/bazelisk-1.18.0.tar.gz
      chmod +x /tmp/bazelisk-1.18.0
      mv /tmp/bazelisk-1.18.0 "$HOME/bin/bazelisk"
      rm /tmp/bazelisk-1.18.0.tar.gz
      echo "Bazelisk installed successfully!"
  fi
  export PATH="$HOME/bin/bazelisk:$PATH"
fi

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
### End of Zinit's installer chunk

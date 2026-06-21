# --- Homebrew Setup ---
if test -f /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
else if test -f /usr/local/bin/brew
    /usr/local/bin/brew shellenv | source
else if test -f /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv | source
end

# --- PATH configuration ---
fish_add_path $HOME/.local/bin

# Android SDK
set -gx ANDROID_HOME $HOME/Library/Android/sdk
set -gx ANDROID_NDK_HOME $ANDROID_HOME/ndk/28.0.13004108
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin

# Java SDK
set -gx JAVA_HOME /Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home

# PNPM configuration
set -gx PNPM_HOME $HOME/Library/pnpm
fish_add_path $PNPM_HOME

# --- Vite+ environment (viteplus.dev) ---
fish_add_path $HOME/.vite-plus/bin
function vp
    if test (count $argv) -ge 2 -a "$argv[1]" = "env" -a "$argv[2]" = "use"
        for arg in $argv
            if test "$arg" = "-h" -o "$arg" = "--help"
                command vp $argv
                return
            end
        end
        set -l vp_out (env VITE_PLUS_ENV_USE_EVAL_ENABLE=1 command vp $argv)
        if test $status -eq 0
            eval $vp_out
        end
    else
        command vp $argv
    end
end

# --- Aliases ---
alias ls="ls --color"
alias c="clear"

# --- Shell Integrations ---
# Starship prompt (initialized statically first)
if command -v starship >/dev/null
    starship init fish | source
end

# Dynamic Light/Dark & SSH config selector
function change_starship_theme --on-event fish_prompt
    set -l dark_mode "Dark"
    if command -v defaults >/dev/null
        set dark_mode (defaults read -g AppleInterfaceStyle 2>/dev/null)
    end
    if test -n "$SSH_CONNECTION"
        # SSH Connection
        if test "$dark_mode" = "Dark"
            set -gx STARSHIP_CONFIG $HOME/.config/starship-ssh.toml
        else
            set -gx STARSHIP_CONFIG $HOME/.config/starship-ssh-light.toml
        end
    else
        # Local Connection
        if test "$dark_mode" = "Dark"
            set -gx STARSHIP_CONFIG $HOME/.config/starship.toml
        else
            set -gx STARSHIP_CONFIG $HOME/.config/starship-light.toml
        end
    end
end

# Zoxide
if command -v zoxide >/dev/null
    zoxide init --cmd cd fish | source
end

# FNM (Fast Node Manager)
if command -v fnm >/dev/null
    fnm env --use-on-cd --shell fish | source
end

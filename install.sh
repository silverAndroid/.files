#!/usr/bin/env bash
#
# Installation script for silverAndroid/.files
#
# This script:
# 1. Installs Homebrew if missing and loads it into PATH.
# 2. Installs core packages (including Stow and Fish) via Homebrew.
# 3. Optionally installs Mosh and configures UFW on Ubuntu (--with-mosh).
# 4. Links dotfiles into $HOME using GNU Stow.
# 5. Sets Fish as the default login shell on macOS and Linux.
# 6. Installs Fisher and configured Fish plugins.
# 7. Sets JAVA_HOME as a Fish universal variable for the current platform.
# 8. Installs Android CLI, initializes it, installs SDK packages, and sets ANDROID_HOME (--skip-android).
# 9. Configures a daily 3:00 AM Homebrew update/upgrade job.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WITH_MOSH=false
SKIP_SHELL=false
SKIP_AUTOUPDATE=false
SKIP_ANDROID=false

BREW_PACKAGES=(
    stow
    fish
    starship
    fnm
    fzf
    zoxide
    openjdk@21
    bazelisk
    glances
)

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERROR] %s\n' "$*" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --with-mosh        Install Mosh and configure UFW firewall (Ubuntu only)
  --skip-shell       Do not change the default login shell to Fish
  --skip-autoupdate  Do not configure the daily Homebrew update/upgrade job
  --skip-android     Do not install Android CLI/SDK or set ANDROID_HOME
  -h, --help         Show this help message
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --with-mosh)
                WITH_MOSH=true
                ;;
            --skip-shell)
                SKIP_SHELL=true
                ;;
            --skip-autoupdate)
                SKIP_AUTOUPDATE=true
                ;;
            --skip-android)
                SKIP_ANDROID=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                err "Unknown option: $1"
                usage >&2
                exit 1
                ;;
        esac
        shift
    done
}

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_ubuntu() {
    [[ -f /etc/os-release ]] && grep -q '^ID=ubuntu$' /etc/os-release
}

is_wsl() {
    grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

load_brew_env() {
    local brew_bin=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_bin="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        brew_bin="/usr/local/bin/brew"
    elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
    fi

    if [[ -n "$brew_bin" ]]; then
        eval "$("$brew_bin" shellenv)"
        return 0
    fi
    return 1
}

install_homebrew() {
    info "Checking for Homebrew..."
    load_brew_env || true

    if command -v brew >/dev/null 2>&1; then
        info "Homebrew is already installed ($(command -v brew))."
        return 0
    fi

    if is_ubuntu; then
        info "Installing Homebrew Linux prerequisites via apt..."
        sudo apt-get update
        sudo apt-get install -y build-essential procps curl file git
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    load_brew_env || true
    if ! command -v brew >/dev/null 2>&1; then
        err "Homebrew installation failed or brew is still not in PATH."
        err "Install Homebrew manually and re-run this script."
        exit 1
    fi

    info "Homebrew installed successfully."
}

install_packages() {
    info "Installing Homebrew packages: ${BREW_PACKAGES[*]}..."
    brew install "${BREW_PACKAGES[@]}"

    # Fallback for fnm if Homebrew did not provide it on this platform.
    if ! command -v fnm >/dev/null 2>&1; then
        info "Installing fnm via upstream installer as fallback..."
        mkdir -p "$HOME/.local/bin"
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    fi
}

setup_ubuntu_mosh() {
    if ! "$WITH_MOSH"; then
        return 0
    fi

    if ! is_ubuntu; then
        warn "--with-mosh is only supported on Ubuntu; skipping."
        return 0
    fi

    info "Installing Mosh server..."
    sudo apt-get update
    sudo apt-get install -y mosh

    if is_wsl; then
        warn "WSL detected; skipping UFW firewall configuration."
        return 0
    fi

    info "Configuring UFW firewall for Mosh..."
    if ! command -v ufw >/dev/null 2>&1; then
        sudo apt-get install -y ufw
    fi

    sudo ufw allow ssh
    sudo ufw allow 60000:61000/udp
    if ! sudo ufw status | grep -q "Status: active"; then
        info "Enabling UFW..."
        sudo ufw --force enable
    fi
    info "UFW configured for SSH and Mosh (UDP 60000-61000)."
}

link_dotfiles() {
    if ! command -v stow >/dev/null 2>&1; then
        err "Stow is not installed or not in PATH."
        exit 1
    fi

    info "Linking dotfiles from $SCRIPT_DIR into $HOME..."
    if ! stow --restow --dir="$SCRIPT_DIR" --target="$HOME" .; then
        err "Stow failed. Resolve any conflicting files in $HOME (or run ./migrate.sh) and try again."
        exit 1
    fi
    info "Dotfiles linked successfully."
}

get_login_shell() {
    local target_user="${SUDO_USER:-$USER}"
    if is_macos; then
        dscl . -read "/Users/$target_user" UserShell 2>/dev/null | awk '{print $2}'
    else
        getent passwd "$target_user" 2>/dev/null | cut -d: -f7
    fi
}

setup_default_shell() {
    if "$SKIP_SHELL"; then
        info "Skipping default shell setup (--skip-shell)."
        return 0
    fi

    local fish_path
    fish_path="$(command -v fish || true)"
    if [[ -z "$fish_path" ]]; then
        warn "fish is not installed; skipping default shell setup."
        return 0
    fi

    local current_shell
    current_shell="$(get_login_shell || true)"
    if [[ "$current_shell" == "$fish_path" ]]; then
        info "Default shell is already set to $fish_path."
        return 0
    fi

    if ! grep -Fxq "$fish_path" /etc/shells; then
        info "Adding $fish_path to /etc/shells..."
        printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    local target_user="${SUDO_USER:-$USER}"
    info "Changing default shell for $target_user to $fish_path..."
    sudo chsh -s "$fish_path" "$target_user"
    info "Default shell changed to Fish. Restart your terminal or log out and back in."
}

setup_fisher() {
    if ! command -v fish >/dev/null 2>&1; then
        warn "fish is not installed; skipping Fisher plugin setup."
        return 0
    fi

    info "Configuring Fisher and plugins..."
    fish -c '
        if not functions -q fisher
            echo "Installing Fisher..."
            curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            and fisher install jorgebucaran/fisher </dev/null
        else
            echo "Fisher is already installed."
        end

        if not fisher list | string match -qi "patrickf1/fzf.fish"
            echo "Installing patrickf1/fzf.fish..."
            fisher install PatrickF1/fzf.fish </dev/null
        else
            echo "patrickf1/fzf.fish is already installed."
        end
    '
}

setup_java_home() {
    info "Configuring JAVA_HOME..."
    local java_home_path=""
    local jdk_prefix=""

    if command -v brew >/dev/null 2>&1; then
        jdk_prefix="$(brew --prefix openjdk@21 2>/dev/null || true)"
    fi

    if is_macos; then
        if [[ -n "$jdk_prefix" && -d "$jdk_prefix/libexec/openjdk.jdk/Contents/Home" ]]; then
            java_home_path="$jdk_prefix/libexec/openjdk.jdk/Contents/Home"
        elif /usr/libexec/java_home -v 21 >/dev/null 2>&1; then
            java_home_path="$(/usr/libexec/java_home -v 21)"
        fi
    else
        if [[ -n "$jdk_prefix" && -x "$jdk_prefix/libexec/bin/java" ]]; then
            java_home_path="$jdk_prefix/libexec"
        elif command -v java >/dev/null 2>&1; then
            java_home_path="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
        fi
    fi

    if [[ -z "$java_home_path" ]]; then
        warn "Could not find a JDK 21 installation; JAVA_HOME was not set."
    else
        export JAVA_HOME="$java_home_path"
        if command -v fish >/dev/null 2>&1; then
            fish -c "set -Ux JAVA_HOME \"$java_home_path\""
            info "JAVA_HOME set to $java_home_path (fish universal variable)."
        else
            warn "fish is not installed; set JAVA_HOME=$java_home_path manually."
        fi
    fi
}

get_android_cli_platform() {
    case "$(uname -s) $(uname -m)" in
        "Linux x86_64")           printf '%s\n' "linux_x86_64" ;;
        "Linux aarch64"|"Linux arm64") printf '%s\n' "linux_arm64" ;;
        "Darwin x86_64")          printf '%s\n' "darwin_x86_64" ;;
        "Darwin arm64")           printf '%s\n' "darwin_arm64" ;;
        *)                        return 1 ;;
    esac
}

get_android_home_path() {
    if is_macos; then
        printf '%s\n' "$HOME/Library/Android/sdk"
    else
        printf '%s\n' "$HOME/Android/Sdk"
    fi
}

setup_android_home() {
    info "Configuring ANDROID_HOME..."
    local android_home_path
    android_home_path="$(get_android_home_path)"

    mkdir -p "$android_home_path"
    export ANDROID_HOME="$android_home_path"

    if command -v fish >/dev/null 2>&1; then
        fish -c "set -Ux ANDROID_HOME \"$android_home_path\""
        info "ANDROID_HOME set to $android_home_path (fish universal variable)."
    else
        warn "fish is not installed; set ANDROID_HOME=$android_home_path manually."
    fi
}

install_android_cli() {
    # Ensure ~/.local/bin is in PATH before running Google's installer so it does not mutate shell rc files.
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"

    if command -v android >/dev/null 2>&1; then
        info "Android CLI is already installed ($(command -v android))."
        return 0
    fi

    local platform
    if ! platform="$(get_android_cli_platform)"; then
        warn "Unsupported OS/architecture for Android CLI ($(uname -s) $(uname -m))."
        return 1
    fi

    info "Installing Android CLI ($platform)..."
    if ! curl -fsSL "https://dl.google.com/android/cli/latest/${platform}/install.sh" | bash; then
        warn "Android CLI installation failed."
        return 1
    fi

    if ! command -v android >/dev/null 2>&1; then
        warn "Android CLI was not found in PATH after installation."
        return 1
    fi
    info "Android CLI installed successfully."
}

resolve_latest_android_sdk_pkg() {
    local android_home_path="$1"
    local pattern="$2"
    local regex="$3"

    android --sdk="$android_home_path" sdk list --all "$pattern" 2>/dev/null \
        | awk '{print $1}' \
        | grep -E "$regex" \
        | sort -V \
        | tail -n 1 || true
}

install_android_sdk() {
    local android_home_path="$1"
    local -a sdk_packages=(
        "platform-tools"
        "cmdline-tools/latest"
        "emulator"
    )

    local latest_platform latest_build_tools
    latest_platform="$(resolve_latest_android_sdk_pkg "$android_home_path" "platforms/*" '^platforms/android-[0-9]+(\.[0-9]+)?$')"
    if [[ -n "$latest_platform" ]]; then
        sdk_packages+=("$latest_platform")
    else
        warn "Could not resolve latest stable Android SDK platform; skipping platform package."
    fi

    latest_build_tools="$(resolve_latest_android_sdk_pkg "$android_home_path" "build-tools/*" '^build-tools/[0-9]+\.[0-9]+\.[0-9]+$')"
    if [[ -n "$latest_build_tools" ]]; then
        sdk_packages+=("$latest_build_tools")
    else
        warn "Could not resolve latest stable Android SDK build-tools; skipping build-tools package."
    fi

    info "Installing Android SDK packages (${sdk_packages[*]}) into $android_home_path..."
    { yes || true; } | android --sdk="$android_home_path" sdk install "${sdk_packages[@]}"
}

setup_android() {
    if "$SKIP_ANDROID"; then
        info "Skipping Android CLI/SDK setup (--skip-android)."
        return 0
    fi

    setup_android_home

    if install_android_cli; then
        info "Initializing Android CLI..."
        android --sdk="$ANDROID_HOME" init </dev/null
        install_android_sdk "$ANDROID_HOME"
    else
        warn "Skipping Android SDK installation because Android CLI is unavailable."
    fi
}

setup_brew_autoupdate() {
    if "$SKIP_AUTOUPDATE"; then
        info "Skipping daily Homebrew update/upgrade job (--skip-autoupdate)."
        return 0
    fi

    info "Configuring daily Homebrew update/upgrade job (3:00 AM)..."
    if is_macos; then
        local launch_agents_dir="$HOME/Library/LaunchAgents"
        local logs_dir="$HOME/Library/Logs"
        local plist_file="$launch_agents_dir/com.user.brew-update-upgrade.plist"
        local domain="gui/$(id -u)"

        mkdir -p "$launch_agents_dir" "$logs_dir"

        cat <<EOF > "$plist_file"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.brew-update-upgrade</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>eval "\$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"; brew update &amp;&amp; brew upgrade</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$logs_dir/brew-update-upgrade.log</string>
    <key>StandardErrorPath</key>
    <string>$logs_dir/brew-update-upgrade.log</string>
</dict>
</plist>
EOF
        chmod 644 "$plist_file"

        launchctl bootout "$domain" "$plist_file" 2>/dev/null || true
        if ! launchctl bootstrap "$domain" "$plist_file" 2>/dev/null; then
            launchctl unload "$plist_file" 2>/dev/null || true
            launchctl load "$plist_file"
        fi
        info "LaunchAgent configured at $plist_file."
    else
        if ! command -v crontab >/dev/null 2>&1; then
            warn "crontab is not installed; skipping daily Homebrew update/upgrade job."
            return 0
        fi

        local cron_tag="# brew-update-upgrade"
        local cron_cmd="0 3 * * * /bin/bash -c 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)\"; brew update && brew upgrade' > /dev/null 2>&1 $cron_tag"
        local existing_cron
        existing_cron="$(crontab -l 2>/dev/null | grep -v "$cron_tag" || true)"

        if [[ -n "$existing_cron" ]]; then
            printf '%s\n%s\n' "$existing_cron" "$cron_cmd" | crontab -
        else
            printf '%s\n' "$cron_cmd" | crontab -
        fi
        info "Crontab entry configured for daily Homebrew updates."
    fi
}

main() {
    parse_args "$@"
    info "Starting installation for silverAndroid/.files..."

    install_homebrew
    install_packages
    setup_ubuntu_mosh
    link_dotfiles
    setup_default_shell
    setup_fisher
    setup_java_home
    setup_android
    setup_brew_autoupdate

    info "Installation complete."
}

main "$@"

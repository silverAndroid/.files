#!/bin/bash
#
# Installation script for silverAndroid/.files
#
# This script will:
# 1. Check for and install Homebrew if not present.
# 2. Install packages from the Brewfile.
# 3. Check for and install Stow if not present.
# 4. Run stow to link the dotfiles from the current directory.
# 5. On Ubuntu, install zsh and set it as the default shell.

echo "Starting installation for silverAndroid/.files..."

# --- Helper Functions ---
is_ubuntu() {
    [ -f /etc/os-release ] && . /etc/os-release && [ "$ID" = "ubuntu" ]
}

# --- Check and Install Homebrew ---
echo "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Attempt to add Homebrew to PATH for the current script execution
    # This depends on the OS and where Homebrew installs.
    # For macOS (Apple Silicon):
    if [ -x "/opt/homebrew/bin/brew" ]; then
        echo "Adding Homebrew (Apple Silicon) to PATH for this session..."
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    # For macOS (Intel) & Linux:
    if [ -x "/usr/local/bin/brew" ]; then
        echo "Adding Homebrew (Intel macOS/Linux) to PATH for this session..."
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    # For Linuxbrew in specific home directory:
    if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        echo "Adding Homebrew (Linuxbrew) to PATH for this session..."
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        sudo apt-get install build-essential procps curl file git
    fi

    if ! command -v brew &> /dev/null; then
        echo "ERROR: Homebrew installation failed or brew is still not in PATH."
        echo "Please install Homebrew manually and re-run this script."
        exit 1
    else
        echo "Homebrew installed successfully."
    fi
else
    echo "Homebrew is already installed."
fi
# --- End Homebrew Check ---

# --- Install Homebrew Packages ---
echo "Installing Homebrew packages..."
if command -v brew &> /dev/null; then
    echo "Using Homebrew to install packages..."
    brew install fish starship fnm fzf zoxide "openjdk@21" bazelisk glances
    echo "Homebrew package installation attempt complete."
else
    echo "WARNING: Homebrew is not available, cannot install packages."
fi
# --- End Homebrew Package Installation ---

# --- Install Fallbacks & Other Tools ---

# Bazelisk
if ! command -v bazel > /dev/null; then
    echo "Installing Bazelisk via curl as fallback..."
    curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-1.18.0.tar.gz -o /tmp/bazelisk-1.18.0.tar.gz
    tar -xf /tmp/bazelisk-1.18.0.tar.gz
    chmod +x /tmp/bazelisk-1.18.0
    mkdir -p "$HOME/bin"
    mv /tmp/bazelisk-1.18.0 "$HOME/bin/bazelisk"
    rm /tmp/bazelisk-1.18.0.tar.gz
    echo "Bazelisk installed successfully!"
fi

# FNM
if ! command -v fnm > /dev/null; then
    echo "Installing fnm via curl as fallback..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
fi

# --- End Fallbacks & Other Tools ---

# --- Ubuntu Specific Setup ---
if is_ubuntu; then
    echo "Ubuntu detected. Running Ubuntu-specific setup..."
    sudo apt-get update

    # Install unzip, as it is required by oh-my-posh installer
    sudo apt-get install -y unzip

    # --- Install fish and set as default shell ---
    echo "Installing fish..."
    sudo apt-add-repository -y ppa:fish-shell/release-3
    sudo apt-get update
    sudo apt-get install -y fish
    echo "Setting fish as the default shell..."
    if [ -x "$(command -v fish)" ]; then
        FISH_PATH=$(command -v fish)
        # Add fish to /etc/shells if it's not already there
        if ! grep -Fxq "$FISH_PATH" /etc/shells; then
            echo "Adding $FISH_PATH to /etc/shells..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells
        fi
        sudo chsh -s "$FISH_PATH" "${SUDO_USER:-$USER}"
        echo "Default shell changed to fish. Please log out and back in for the change to take effect."
    else
        echo "WARNING: fish installation seems to have failed. Skipping setting it as default shell."
    fi
    # --- End fish Setup ---

    # --- Set up Mosh Server ---
    echo "Installing Mosh server..."
    sudo apt-get install -y mosh

    echo "Configuring firewall for Mosh..."
    # Install ufw if not present
    if ! command -v ufw &> /dev/null; then
        echo "ufw not found. Installing..."
        sudo apt-get install -y ufw
    fi

    # Configure ufw if available
    if command -v ufw &> /dev/null; then
        sudo ufw allow ssh
        sudo ufw allow 60000:61000/udp
        if ! sudo ufw status | grep -q "Status: active"; then
            echo "ufw is inactive. Enabling..."
            sudo ufw --force enable
        fi
        echo "ufw configured for Mosh."
    else
        echo "WARNING: ufw could not be installed. Skipping firewall configuration."
        echo "Please manually open UDP ports 60000-61000 for Mosh to work."
    fi
    # --- End Mosh Server Setup ---
fi
# --- End Ubuntu Specific Setup ---

# --- Check and Install Stow ---
echo "Checking for Stow..."
if ! command -v stow &> /dev/null; then
    echo "Stow not found. Attempting to install Stow using Homebrew..."
    if command -v brew &> /dev/null; then
        brew install stow
        if ! command -v stow &> /dev/null; then
            echo "ERROR: Stow installation failed even with Homebrew."
            echo "Please install Stow manually and re-run this script."
            exit 1
        else
            echo "Stow installed successfully via Homebrew."
        fi
    else
        echo "ERROR: Homebrew is not available, and Stow is not installed."
        echo "Please install Homebrew and Stow manually, then re-run this script."
        exit 1
    fi
else
    echo "Stow is already installed."
fi
# --- End Stow Check ---

# --- Run Stow ---
echo "Running Stow to link dotfiles from the current directory ($(pwd))..."

if ! command -v stow &> /dev/null; then
    echo "ERROR: Stow command not found. Stow installation may have failed or was skipped."
    echo "Please ensure Stow is installed and in your PATH."
elif [ ! -f ".stow-config" ] && [ ! -d ".git" ]; then # Basic check if this looks like the dotfiles repo
    echo "WARNING: Current directory ($(pwd)) might not be the root of the dotfiles repository (missing .git or .stow-config)."
    echo "Please ensure you are running this script from the root of your dotfiles clone."
    read -r -p "Proceed with 'stow .' in the current directory? (y/N): " confirm_stow
    if [[ ! "$confirm_stow" =~ ^[yY](es)?$ ]]; then
        echo "Stow operation cancelled by user."
    else
        echo "Proceeding with 'stow .' in $(pwd)..."
        stow .
        if [ $? -ne 0 ]; then
            echo "ERROR: Stow command failed. Please check for conflicts or issues."
        else
            echo "Stow command completed successfully."
        fi
    fi
else
    stow .
    if [ $? -ne 0 ]; then
        echo "ERROR: Stow command failed. Please check for conflicts or issues in $(pwd)."
    else
        echo "Stow command completed successfully."
    fi
fi
# --- End Run Stow ---

# --- Install Fisher and fzf.fish ---
if command -v fish &> /dev/null; then
    echo "Configuring Fisher and plugins..."
    fish -c '
        status job-control full
        if not functions -q fisher
            echo "Installing Fisher..."
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher </dev/null
        else
            echo "Fisher is already installed."
        end
        echo "Installing fzf.fish plugin..."
        fisher install PatrickF1/fzf.fish </dev/null
    '
else
    echo "WARNING: fish is not installed; skipping Fisher and fzf.fish plugin installation."
fi

# --- Setup Homebrew Daily Update/Upgrade Cron Job ---
echo "Setting up daily Homebrew update/upgrade job (3:00 AM)..."
if [ "$(uname)" = "Darwin" ]; then
    # macOS: Use LaunchAgent
    LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
    PLIST_FILE="$LAUNCH_AGENTS_DIR/com.user.brew-update-upgrade.plist"
    mkdir -p "$LAUNCH_AGENTS_DIR"
    
    # Generate the plist file dynamically to use the correct HOME and USER
    cat <<EOF > "$PLIST_FILE"
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
    <string>$HOME/Library/Logs/brew-update-upgrade.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/brew-update-upgrade.log</string>
</dict>
</plist>
EOF
    chmod 644 "$PLIST_FILE"
    
    # Load the LaunchAgent
    echo "Loading LaunchAgent..."
    launchctl unload "$PLIST_FILE" 2>/dev/null
    launchctl load "$PLIST_FILE"
    echo "Daily Homebrew update/upgrade LaunchAgent configured at $PLIST_FILE"
else
    # Linux: Use crontab
    echo "Configuring crontab entry..."
    CRON_CMD="0 3 * * * /bin/bash -c 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)\"; brew update && brew upgrade' > /dev/null 2>&1"
    (crontab -l 2>/dev/null | grep -v "brew-update-upgrade"; echo "$CRON_CMD") | crontab -
    echo "Daily Homebrew update/upgrade crontab entry configured."
fi

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
    brew install fzf
    brew install zoxide
    brew install "openjdk@21"
    brew install bazelisk
    brew install nvm
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

# NVM
if ! command -v nvm > /dev/null; then
    echo "Installing nvm via curl as fallback..."
    export NVM_DIR="$HOME/.nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
# Create nvm directory, the nvm installer might create it, but -p makes it safe
mkdir -p "$HOME/.nvm"

# Zinit
echo "Installing Zinit..."
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
   echo "Zinit installed."
else
   echo "Zinit is already installed."
fi

# --- End Fallbacks & Other Tools ---

# --- Ubuntu Specific Setup ---
if is_ubuntu; then
    echo "Ubuntu detected. Running Ubuntu-specific setup..."
    sudo apt-get update

    # Install unzip, as it is required by oh-my-posh installer
    sudo apt-get install -y unzip

    # --- Install zsh and set as default shell ---
    echo "Installing zsh..."
    sudo apt-get install -y zsh
    echo "Setting zsh as the default shell..."
    if [ -x "$(command -v zsh)" ]; then
        ZSH_PATH=$(command -v zsh)
        # Add zsh to /etc/shells if it's not already there
        if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
            echo "Adding $ZSH_PATH to /etc/shells..."
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        sudo chsh -s "$ZSH_PATH" "${SUDO_USER:-$USER}"
        echo "Default shell changed to zsh. Please log out and back in for the change to take effect."
    else
        echo "WARNING: zsh installation seems to have failed. Skipping setting it as default shell."
    fi
    # --- End zsh Setup ---

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

# --- Install Oh My Posh ---
curl -s https://ohmyposh.dev/install.sh | bash -s

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

# (Rest of the script will follow)

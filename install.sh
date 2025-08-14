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

# --- Helper Functions ---
is_ubuntu() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            return 0 # 0 is success in shell scripting
        fi
    fi
    return 1 # 1 is failure
}

echo "Starting installation for silverAndroid/.files..."

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
    brew install "openjdk@23"
    brew install bazelisk
    echo "Homebrew package installation attempt complete."
else
    echo "WARNING: Homebrew is not available, cannot install packages."
fi
# --- End Homebrew Package Installation ---

# --- OS-specific Prerequisite Installation ---
if is_ubuntu; then
    echo "Ubuntu detected. Installing prerequisites..."
    sudo apt-get update
    # Install unzip on Ubuntu, as it is required by oh-my-posh installer
    sudo apt-get install -y unzip
    echo "Installing zsh..."
    sudo apt-get install -y zsh
fi

# --- Install Oh My Posh ---
# Install unzip on Ubuntu, as it is required by oh-my-posh installer
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        echo "Ubuntu detected. Installing dependencies..."
        sudo apt-get update
        sudo apt-get install -y unzip # for oh-my-posh

        # --- Set up Mosh Server ---
        echo "Installing Mosh server..."
        sudo apt-get install -y mosh

        echo "Configuring firewall for Mosh..."
        # Check if ufw is installed, and install it if it is not.
        if ! command -v ufw &> /dev/null; then
            echo "ufw not found. Installing..."
            sudo apt-get install -y ufw
        fi

        # Now, configure ufw.
        # We check again in case installation failed.
        if command -v ufw &> /dev/null; then
            echo "Configuring ufw for Mosh..."
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
fi
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

# --- Set Default Shell on Ubuntu ---
if is_ubuntu; then
    if command -v zsh &> /dev/null; then
        echo "Setting zsh as the default shell..."
        # The following command might prompt for a password
        if chsh -s "$(which zsh)"; then
            echo "Default shell changed to zsh."
            echo "You may need to log out and log back in for the change to take full effect."
        else
            echo "Failed to change the default shell. Please try running 'chsh -s \$(which zsh)' manually."
        fi
    else
        echo "WARNING: zsh is not installed, so it cannot be set as the default shell."
    fi
fi

# (Rest of the script will follow)

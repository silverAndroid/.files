#!/bin/bash
#
# Installation script for silverAndroid/.files
#
# This script will:
# 1. Check for and install Homebrew if not present.
# 2. Install packages from the Brewfile.
# 3. Check for and install Stow if not present.
# 4. Run stow to link the dotfiles from the current directory.

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

# --- Install Packages from Brewfile ---
echo "Installing packages from Brewfile..."
if [ -f "./Brewfile" ]; then
    if command -v brew &> /dev/null; then
        echo "Using Homebrew to install packages from Brewfile..."
        brew install fzf
        brew install zoxide
        brew install "openjdk@23"
        brew install bazelisk
        echo "Brewfile packages installation attempt complete."
    else
        echo "WARNING: Homebrew is not available, cannot install packages from Brewfile."
    fi
else
    echo "WARNING: Brewfile not found in the current directory. Skipping package installation from Brewfile."
fi
# --- End Brewfile Package Installation ---

# --- Install Oh My Posh ---
# Install unzip on Ubuntu, as it is required by oh-my-posh installer
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        echo "Ubuntu detected. Installing unzip..."
        sudo apt-get update
        sudo apt-get install -y unzip
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

# (Rest of the script will follow)

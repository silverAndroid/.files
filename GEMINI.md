# Gemini Context

This file provides context to the Gemini CLI.

## About This Repository

This repository contains personal dotfiles, which are managed and synchronized using GNU Stow. The primary purpose is to maintain a consistent development environment across multiple machines.

Key characteristics of this repository:
- **Dotfile Management**: Uses `stow` to create symbolic links for configuration files (e.g., `.zshrc`, `.nirc`).
- **Package Management**: Relies on Homebrew for installing and managing software dependencies, with a `Brewfile` listing the required packages.
- **Automated Setup**: An `install.sh` script is provided to automate the setup process, including installing Homebrew, required packages, and running `stow`.
- **Manual Setup**: Manual installation instructions are also available for users who prefer more control.
- **Zsh Plugins**: Zsh plugins are managed by `zinit` within the `.zshrc` file.

When reviewing pull requests, please consider the following:
- Changes should be consistent with the existing dotfile structure.
- Modifications to the `install.sh` script should be safe and idempotent.
- New dependencies should be added to the `Brewfile`.
- The primary goal is to maintain a clean and synchronized set of dotfiles.

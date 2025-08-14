# .files

Contains my dotfiles that I sync via [Stow](https://www.gnu.org/software/stow/).

## Automated Installation (Recommended)

This repository now includes an automated installation script (`install.sh`) that handles all necessary setup steps.

To use the script:

1.  **Clone this repository to your desired location (typically `~/dotfiles`):**
    ```bash
    git clone https://github.com/silverAndroid/.files ~/dotfiles
    ```
    (If you choose a different location than `~/dotfiles`, `stow` will still link files relative to that location's parent directory. For example, cloning to `~/mydots` would have `stow` link to `~`.)

2.  **Navigate into the cloned repository's directory:**
    ```bash
    cd ~/dotfiles 
    # Or cd to the custom location you used
    ```

3.  **Run the installation script:**
    ```bash
    ./install.sh
    ```

The script will:
*   Check for and install [Homebrew](https://brew.sh/) if it's not already present.
*   Install required software packages (e.g., `oh-my-posh`, `fzf`, `zoxide`, etc.) using Homebrew.
*   Check for and install [Stow](https://www.gnu.org/software/stow/) if it's not already present.
*   Run `stow .` from within the repository's root directory to create symbolic links (typically to your home directory, if you cloned to `~/dotfiles`).

## Manual Installation

If you prefer to set things up manually, you will need to:

1.  Ensure [Homebrew](https://brew.sh/) is installed.
2.  Install packages: You can inspect the `install.sh` script to see the list of packages to install (e.g., `fzf`, `zoxide`, `stow`) and install them using `brew install <package>`.
3.  Ensure [Stow](https://www.gnu.org/software/stow/) is installed.
4.  Clone this repository to `~/dotfiles`:
    ```bash
    git clone https://github.com/silverAndroid/.files ~/dotfiles
    ```
5.  Navigate into the directory and run Stow:
    ```bash
    cd ~/dotfiles
    stow .
    ```

## Software Management

*   Core software dependencies are managed via Homebrew and are installed by the `install.sh` script.
*   Zsh plugins are managed by `zinit` as configured in `.zshrc`.

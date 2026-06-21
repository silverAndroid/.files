#!/bin/bash
#
# Migration script from Zsh + Oh My Posh to Fish + Starship
#

echo "Starting migration from Zsh/Oh-My-Posh to Fish/Starship..."

# --- Backup existing configs ---
BACKUP_DIR="$HOME/.zsh_to_fish_backup_$(date +%Y%m%d_%H%M%S)"
echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

backup_file() {
    local filepath="$1"
    if [ -f "$filepath" ] && [ ! -L "$filepath" ]; then
        echo "Backing up $filepath to $BACKUP_DIR..."
        mv "$filepath" "$BACKUP_DIR/"
    elif [ -L "$filepath" ]; then
        echo "Removing existing symlink $filepath..."
        rm "$filepath"
    fi
}

backup_file "$HOME/.zshrc"
backup_file "$HOME/.omp.yaml"
backup_file "$HOME/.config/starship.toml"
backup_file "$HOME/.config/fish/config.fish"

# --- Run the main installation script ---
echo "Running install.sh..."
if [ -f "./install.sh" ]; then
    chmod +x ./install.sh
    ./install.sh
else
    echo "ERROR: install.sh not found. Please run this script from the root of your dotfiles repository."
    exit 1
fi

# --- Migrate Zsh History to Fish ---
echo "Checking for Zsh history to migrate..."
python3 -c '
import os
import re
import time

zsh_history_path = os.path.expanduser("~/.zsh_history")
fish_history_dir = os.path.expanduser("~/.local/share/fish")
fish_history_path = os.path.join(fish_history_dir, "fish_history")

if os.path.exists(zsh_history_path):
    print("Migrating Zsh history to Fish...")
    os.makedirs(fish_history_dir, exist_ok=True)
    
    existing_cmds = set()
    if os.path.exists(fish_history_path):
        try:
            with open(fish_history_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("- cmd:"):
                        existing_cmds.add(line[6:].strip())
        except Exception:
            pass

    # Extended history format: : 1718029012:0;command
    pattern = re.compile(r"^:\s*(\d+):\d+;(.*)$")

    imported_count = 0
    try:
        with open(zsh_history_path, "r", encoding="utf-8", errors="ignore") as zsh_f, \
             open(fish_history_path, "a", encoding="utf-8") as fish_f:
            
            curr_cmd = []
            curr_time = int(time.time())
            
            for line in zsh_f:
                match = pattern.match(line)
                if match:
                    if curr_cmd:
                        cmd_str = "".join(curr_cmd).strip()
                        if cmd_str and cmd_str not in existing_cmds:
                            # Escape double quotes or backslashes if needed, but standard yaml works with simple format
                            fish_f.write(f"- cmd: {cmd_str}\n  when: {curr_time}\n")
                            imported_count += 1
                    
                    curr_time = int(match.group(1))
                    curr_cmd = [match.group(2)]
                elif line.startswith(":"):
                    if curr_cmd:
                        cmd_str = "".join(curr_cmd).strip()
                        if cmd_str and cmd_str not in existing_cmds:
                            fish_f.write(f"- cmd: {cmd_str}\n  when: {curr_time}\n")
                            imported_count += 1
                    curr_time = int(time.time())
                    curr_cmd = [line.lstrip(":").strip()]
                else:
                    if curr_cmd:
                        curr_cmd.append(line)
                    else:
                        curr_cmd = [line]
                        curr_time = int(time.time())
            
            if curr_cmd:
                cmd_str = "".join(curr_cmd).strip()
                if cmd_str and cmd_str not in existing_cmds:
                    fish_f.write(f"- cmd: {cmd_str}\n  when: {curr_time}\n")
                    imported_count += 1

        print(f"Successfully migrated {imported_count} unique command history items!")
    except Exception as e:
        print(f"WARNING: Failed to migrate history: {e}")
else:
    print("No existing Zsh history found to migrate.")
'

# --- Change Default Shell (macOS specific, Linux is handled in install.sh) ---
if [ "$(uname)" = "Darwin" ]; then
    echo "Configuring Fish as the default shell on macOS..."
    # Find fish path
    if [ -x "/opt/homebrew/bin/fish" ]; then
        FISH_PATH="/opt/homebrew/bin/fish"
    elif [ -x "/usr/local/bin/fish" ]; then
        FISH_PATH="/usr/local/bin/fish"
    else
        FISH_PATH=$(command -v fish)
    fi

    if [ -n "$FISH_PATH" ]; then
        # Add fish to /etc/shells if not already present
        if ! grep -Fxq "$FISH_PATH" /etc/shells; then
            echo "Adding $FISH_PATH to /etc/shells..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells
        fi
        
        # Change default shell
        echo "Setting default shell to $FISH_PATH..."
        sudo chsh -s "$FISH_PATH" "$USER"
        echo "Default shell changed to Fish. Please restart your terminal/session."
    else
        echo "WARNING: Fish binary not found. Please make sure Fish is installed and run: chsh -s <path_to_fish>"
    fi
fi

echo "Migration completed successfully!"

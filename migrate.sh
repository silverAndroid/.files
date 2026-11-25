#!/usr/bin/env bash
#
# Migration script from Zsh + Oh My Posh to Fish + Starship.
#
# This script:
# 1. Backs up legacy Zsh/Oh-My-Posh files and conflicting target dotfiles.
# 2. Runs install.sh (forwarding any CLI flags).
# 3. Imports unique command history from ~/.zsh_history into Fish history.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR=""

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERROR] %s\n' "$*" >&2; }

ensure_backup_dir() {
    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$HOME/.zsh_to_fish_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        info "Created backup directory: $BACKUP_DIR"
    fi
}

backup_path() {
    local target="$1"
    local rel_path="${target#"$HOME"/}"

    if [[ -L "$target" ]]; then
        local resolved
        resolved="$(readlink -f "$target" 2>/dev/null || true)"
        if [[ -n "$resolved" && "$resolved" == "$SCRIPT_DIR/"* ]]; then
            return 0
        fi
        info "Removing existing symlink $target..."
        rm "$target"
    elif [[ -e "$target" ]]; then
        ensure_backup_dir
        local dest="$BACKUP_DIR/$rel_path"
        mkdir -p "$(dirname "$dest")"
        info "Backing up $target to $dest..."
        mv "$target" "$dest"
    fi
}

backup_existing_configs() {
    local files=(
        "$HOME/.zshrc"
        "$HOME/.omp.yaml"
        "$HOME/.nirc"
        "$HOME/.config/starship.toml"
        "$HOME/.config/starship-ssh.toml"
        "$HOME/.config/fish/config.fish"
    )

    for filepath in "${files[@]}"; do
        backup_path "$filepath"
    done
}

migrate_zsh_history() {
    local zsh_history="$HOME/.zsh_history"
    if [[ ! -f "$zsh_history" ]]; then
        info "No ~/.zsh_history found; skipping history migration."
        return 0
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        warn "python3 is not installed; skipping Zsh history migration."
        return 0
    fi

    info "Migrating Zsh history to Fish..."
    python3 - <<'PY'
import os
import re
import time

zsh_history_path = os.path.expanduser("~/.zsh_history")
fish_history_dir = os.path.expanduser("~/.local/share/fish")
fish_history_path = os.path.join(fish_history_dir, "fish_history")

def unmetafy(data: bytes) -> bytes:
    """Decode Zsh metafied bytes (0x83 followed by byte ^ 0x20)."""
    out = bytearray()
    i = 0
    n = len(data)
    while i < n:
        if data[i] == 0x83 and i + 1 < n:
            out.append(data[i + 1] ^ 0x20)
            i += 2
        else:
            out.append(data[i])
            i += 1
    return bytes(out)

def escape_fish_cmd(cmd: str) -> str:
    """Escape backslashes and newlines for fish_history format."""
    return cmd.replace("\\", "\\\\").replace("\n", "\\n")

os.makedirs(fish_history_dir, exist_ok=True)

existing_cmds = set()
if os.path.exists(fish_history_path):
    with open(fish_history_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            if line.startswith("- cmd: "):
                existing_cmds.add(line[7:].rstrip("\n"))

with open(zsh_history_path, "rb") as f:
    raw = unmetafy(f.read()).decode("utf-8", errors="replace")

# Extended history format: ": 1718029012:0;command"
ext_pattern = re.compile(r"^:\s*(\d+):\d+;(.*)$")

entries = []
curr_lines = []
curr_time = int(time.time())

def flush_entry():
    if not curr_lines:
        return
    cmd = "\n".join(curr_lines).strip()
    if cmd:
        entries.append((cmd, curr_time))

for raw_line in raw.splitlines():
    if curr_lines and curr_lines[-1].endswith("\\"):
        # Continuation of a multiline Zsh history command.
        curr_lines[-1] = curr_lines[-1][:-1]
        curr_lines.append(raw_line)
        continue

    match = ext_pattern.match(raw_line)
    if match:
        flush_entry()
        curr_time = int(match.group(1))
        curr_lines = [match.group(2)]
    else:
        flush_entry()
        curr_time = int(time.time())
        curr_lines = [raw_line]

flush_entry()

imported_count = 0
with open(fish_history_path, "a", encoding="utf-8") as fish_f:
    for cmd, ts in entries:
        escaped = escape_fish_cmd(cmd)
        if escaped and escaped not in existing_cmds:
            fish_f.write(f"- cmd: {escaped}\n  when: {ts}\n")
            existing_cmds.add(escaped)
            imported_count += 1

print(f"[INFO] Migrated {imported_count} unique command history entries to Fish.")
PY
}

main() {
    info "Starting migration from Zsh/Oh-My-Posh to Fish/Starship..."

    backup_existing_configs

    if [[ ! -f "$SCRIPT_DIR/install.sh" ]]; then
        err "install.sh not found in $SCRIPT_DIR."
        exit 1
    fi

    info "Running install.sh..."
    bash "$SCRIPT_DIR/install.sh" "$@"

    migrate_zsh_history

    if [[ -n "$BACKUP_DIR" ]]; then
        info "Previous configs were backed up to: $BACKUP_DIR"
    fi
    info "Migration completed successfully."
}

main "$@"

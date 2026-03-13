#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo 'brew install colima docker'
brew install colima docker

# Symlink ~/bin/aman to the aman script
mkdir -p ~/bin
ln -sf "$SCRIPT_DIR/aman" ~/bin/aman

echo "Setup complete: ~/bin/aman -> $SCRIPT_DIR/aman"

# Copy AI tool configs into var/
mkdir -p "$SCRIPT_DIR/var"

# List and prompt before removing existing configs
existing=()
for item in .claude .claude.json .copilot .gemini; do
    if [ -e "$SCRIPT_DIR/var/$item" ]; then
        existing+=("$item")
    fi
done

if [ ${#existing[@]} -gt 0 ]; then
    echo "Existing configs in var/:"
    for item in "${existing[@]}"; do
        echo "  $item"
    done
    read -p "Remove these before copying? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for item in "${existing[@]}"; do
            rm -rf "$SCRIPT_DIR/var/$item"
        done
    fi
fi

cp -r ~/.claude "$SCRIPT_DIR/var/.claude"
cp ~/.claude.json "$SCRIPT_DIR/var/.claude.json"
cp -r ~/.copilot "$SCRIPT_DIR/var/.copilot" 2>/dev/null || true
cp -r ~/.gemini "$SCRIPT_DIR/var/.gemini" 2>/dev/null || true

echo "Copied configs to $SCRIPT_DIR/var/"

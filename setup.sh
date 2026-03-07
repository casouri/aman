#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo 'brew install colima docker'
brew install colima docker

# Symlink ~/bin/aman to the aman script
mkdir -p ~/bin
ln -sf "$SCRIPT_DIR/aman" ~/bin/aman

echo "Setup complete: ~/bin/aman -> $SCRIPT_DIR/aman"

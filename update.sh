#!/usr/bin/env bash

# ==============================================================================
# Updater for DNS Switcher
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/Mr-Meshky/dns-switcher.git"

echo "==============================================="
echo "         Updating DNS Switcher...              "
echo "==============================================="

if [ -d "$SCRIPT_DIR/.git" ]; then
    echo "Pulling latest updates from Git repository..."
    git -C "$SCRIPT_DIR" pull
else
    echo "Directory is not a Git repo. Cloning latest version..."
    TMP_DIR=$(mktemp -d)
    git clone "$REPO_URL" "$TMP_DIR/dns-switcher"
    cp -r "$TMP_DIR/dns-switcher/"* "$SCRIPT_DIR/"
    rm -rf "$TMP_DIR"
fi

# Re-run installer to ensure permissions and aliases are fresh
bash "$SCRIPT_DIR/install.sh"

echo "✓ DNS Switcher is now up to date!"

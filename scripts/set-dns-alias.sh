#!/usr/bin/env bash

# ==============================================================================
# Setup alias and PATH symlink for dns-switcher
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DNS_SWITCHER_BIN="${SCRIPT_DIR}/dns-switcher.sh"

if [ ! -f "$DNS_SWITCHER_BIN" ]; then
    echo "Error: dns-switcher.sh not found in $SCRIPT_DIR"
    exit 1
fi

chmod +x "$DNS_SWITCHER_BIN"

# 1. Try to create symlink in ~/.local/bin or /usr/local/bin
USER_BIN_DIR="$HOME/.local/bin"
mkdir -p "$USER_BIN_DIR" 2>/dev/null

if [ -d "$USER_BIN_DIR" ]; then
    ln -sf "$DNS_SWITCHER_BIN" "$USER_BIN_DIR/change-dns"
    ln -sf "$DNS_SWITCHER_BIN" "$USER_BIN_DIR/dns-switcher"
    echo "✓ Symlinks created in $USER_BIN_DIR (change-dns, dns-switcher)"
fi

# 2. Add aliases to shell configuration files
SHELL_NAME=$(basename "$SHELL")
CONFIG_FILES=()

case "$SHELL_NAME" in
    zsh)
        CONFIG_FILES=("$HOME/.zshrc")
        ;;
    bash)
        CONFIG_FILES=("$HOME/.bashrc" "$HOME/.bash_profile")
        ;;
    fish)
        CONFIG_FILES=("$HOME/.config/fish/config.fish")
        ;;
    *)
        CONFIG_FILES=("$HOME/.profile" "$HOME/.bashrc")
        ;;
esac

ALIAS_LINE="alias change-dns='\"${DNS_SWITCHER_BIN}\"'"
ALIAS_LINE_2="alias dns-switcher='\"${DNS_SWITCHER_BIN}\"'"

for conf in "${CONFIG_FILES[@]}"; do
    if [ -f "$conf" ] || [ "$conf" == "$HOME/.zshrc" ] || [ "$conf" == "$HOME/.bashrc" ]; then
        touch "$conf" 2>/dev/null
        
        # Ensure ~/.local/bin is in PATH if added
        if ! grep -q '.local/bin' "$conf" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$conf"
        fi

        if ! grep -qF "alias change-dns=" "$conf" 2>/dev/null; then
            echo "$ALIAS_LINE" >> "$conf"
            echo "$ALIAS_LINE_2" >> "$conf"
            echo "✓ Added aliases to $conf"
        else
            # Update existing alias to point to current location
            sed -i.bak '/alias change-dns=/d' "$conf" 2>/dev/null || sed -i '' '/alias change-dns=/d' "$conf" 2>/dev/null
            sed -i.bak '/alias dns-switcher=/d' "$conf" 2>/dev/null || sed -i '' '/alias dns-switcher=/d' "$conf" 2>/dev/null
            echo "$ALIAS_LINE" >> "$conf"
            echo "$ALIAS_LINE_2" >> "$conf"
            rm -f "${conf}.bak" 2>/dev/null
            echo "✓ Updated aliases in $conf"
        fi
    fi
done

echo "Please run 'source ~/.zshrc' (or your shell config file) to reload."
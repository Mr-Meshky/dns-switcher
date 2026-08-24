#!/usr/bin/env bash

# ==============================================================================
# Configure safe sudo rules for passwordless DNS switching
# ==============================================================================

CURRENT_USER="$USER"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/dns-switcher.sh"

OS_TYPE=$(uname -s)

echo "Configuring passwordless sudo rule for DNS switcher..."

if [[ "$OS_TYPE" == "Linux" ]]; then
    SUDOERS_FILE="/etc/sudoers.d/dns-switcher"
    TMP_FILE=$(mktemp)
    
    echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: ${SCRIPT_PATH}" > "$TMP_FILE"
    echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/resolv.conf, /usr/bin/resolvectl, /usr/bin/systemd-resolve" >> "$TMP_FILE"
    
    if sudo visudo -cf "$TMP_FILE" >/dev/null 2>&1; then
        sudo cp "$TMP_FILE" "$SUDOERS_FILE"
        sudo chmod 0440 "$SUDOERS_FILE"
        echo "✓ Linux sudoers rule configured safely at $SUDOERS_FILE"
    else
        echo "Warning: Sudoers rule syntax check failed, skipped."
    fi
    rm -f "$TMP_FILE"

elif [[ "$OS_TYPE" == "Darwin" ]]; then
    # On macOS, networksetup, dscacheutil, and killall require sudo
    SUDOERS_DIR="/private/etc/sudoers.d"
    SUDOERS_FILE="$SUDOERS_DIR/dns-switcher"
    
    sudo mkdir -p "$SUDOERS_DIR" 2>/dev/null
    TMP_FILE=$(mktemp)
    
    echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: /usr/sbin/networksetup, /usr/bin/dscacheutil, /usr/bin/killall" > "$TMP_FILE"
    echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: ${SCRIPT_PATH}" >> "$TMP_FILE"

    if sudo visudo -cf "$TMP_FILE" >/dev/null 2>&1; then
        sudo cp "$TMP_FILE" "$SUDOERS_FILE" 2>/dev/null
        sudo chmod 0440 "$SUDOERS_FILE" 2>/dev/null
        echo "✓ macOS sudoers rule configured at $SUDOERS_FILE"
    else
        echo "Notice: Could not write separate sudoers file. Sudo password will be prompted when needed."
    fi
    rm -f "$TMP_FILE"
fi
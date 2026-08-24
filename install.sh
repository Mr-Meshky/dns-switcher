#!/usr/bin/env bash

# ==============================================================================
# Installer for DNS Switcher
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DNS_SWITCHER_SCRIPT="$SCRIPT_DIR/scripts/dns-switcher.sh"
ADD_SUDO_RULE_SCRIPT="$SCRIPT_DIR/scripts/add-sudo-rule.sh"
SET_DNS_ALIAS_SCRIPT="$SCRIPT_DIR/scripts/set-dns-alias.sh"

echo "==============================================="
echo "       Installing DNS Switcher v3.0.0          "
echo "==============================================="

if [[ ! -f "$DNS_SWITCHER_SCRIPT" || ! -f "$ADD_SUDO_RULE_SCRIPT" || ! -f "$SET_DNS_ALIAS_SCRIPT" ]]; then
    echo "Error: Required files are missing from $SCRIPT_DIR/scripts."
    exit 1
fi

chmod +x "$DNS_SWITCHER_SCRIPT"
chmod +x "$ADD_SUDO_RULE_SCRIPT"
chmod +x "$SET_DNS_ALIAS_SCRIPT"

# Run setup scripts
bash "$SET_DNS_ALIAS_SCRIPT"
bash "$ADD_SUDO_RULE_SCRIPT"

echo ""
echo "==============================================="
echo "   Installation Completed Successfully! 🎉    "
echo "==============================================="
echo ""
echo "You can now run:"
echo "  change-dns                # Launch interactive menu"
echo "  change-dns set 403        # Set DNS directly"
echo "  change-dns clear          # Reset to default"
echo "  change-dns ping           # Measure DNS latency"
echo "  change-dns test           # Test anti-sanction benchmark"
echo "  change-dns --help         # Show full CLI options"
echo ""
echo "Tip: Run 'source ~/.zshrc' (or your shell config) to use the alias immediately."
echo ""

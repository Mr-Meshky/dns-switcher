#!/bin/bash

dns_switcher_script="./scripts/dns-switcher.sh"
add_sudo_rule_script="./scripts/add-sudo-rule.sh"
set_dns_alias_script="./scripts/set-dns-alias.sh"

if [[ ! -f $dns_switcher_script || ! -f $add_sudo_rule_script || ! -f $set_dns_alias_script ]]; then
    echo "Error: One or more required files are missing."
    exit 1
fi

chmod +x $set_dns_alias_script
chmod +x $dns_switcher_script
chmod +x $add_sudo_rule_script


$add_sudo_rule_script
$set_dns_alias_script

echo "Installation completed. Please run 'source ~/.bashrc' or 'source ~/.zshrc' depending on your shell."

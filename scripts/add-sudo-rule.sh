#!/bin/bash

current_user=$(echo $USER)
current_dir=$(pwd)
script_path="${current_dir}/scripts/dns-switcher.sh"
line="${current_user} ALL=(ALL) NOPASSWD: ${script_path}"

OS_TYPE=$(uname)

if [[ "$OS_TYPE" == "Linux" ]]; then
    sudo bash -c "echo '${line}' >> /etc/sudoers"
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    sudo bash -c "echo '${line}' >> /private/etc/sudoers"
else
    echo "Unsupported OS: $OS_TYPE"
    exit 1
fi
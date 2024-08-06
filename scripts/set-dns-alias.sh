#!/bin/bash

current_dir=$(pwd)

script_name="dns-switcher.sh"

alias_command="alias change-dns='sudo ${current_dir}/scripts/${script_name}'"

shell_name=$(basename "$SHELL")

case "$shell_name" in
    bash)
        config_file="$HOME/.bashrc"
        ;;
    zsh)
        config_file="$HOME/.zshrc"
        ;;
    ksh)
        config_file="$HOME/.kshrc"
        ;;
    *)
        echo "Unsupported shell: $shell_name"
        exit 1
        ;;
esac

if ! grep -qF "$alias_command" "$config_file"; then
    echo "$alias_command" >> "$config_file"
    echo "Alias added to $config_file"
else
    echo "Alias already exists in $config_file"
fi

echo "Please run 'source $config_file' to apply the changes."

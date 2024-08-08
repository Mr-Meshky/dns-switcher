#!/bin/bash

current_user=$(echo $USER)

current_dir=$(pwd)

script_path="${current_dir}/scripts/dns-switcher.sh"

line="${current_user} ALL=(ALL) NOPASSWD: ${script_path}"

sudo bash -c "echo '${line}' >> /etc/sudoers"

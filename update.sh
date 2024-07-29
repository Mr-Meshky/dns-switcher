#!/bin/bash

REPO_URL="https://github.com/Mr-Meshky/dns-switcher.git"
REPO_DIR="dns-switcher"

if [ -d ".git" ]; then
    echo "Current directory is a Git repository."
    echo "Updating repository..."
    git pull
else  
    echo "Current directory is not a Git repository."
    if [ -d "$REPO_DIR" ]; then
        echo "$REPO_DIR directory exists."
        cd "$REPO_DIR"
        echo "Updating repository in $REPO_DIR..."
        git pull
    else
        echo "$REPO_DIR directory does not exist. Cloning repository..."
        git clone "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
    fi
fi

echo "Update completed."

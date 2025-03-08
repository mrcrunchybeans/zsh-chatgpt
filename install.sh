#!/bin/bash

set -e  # Exit on error

# Define variables
SCRIPT_URL="https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/chatgpt_shell.sh"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/install.sh"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# Function to install dependencies
install_dependencies() {
    echo "Installing Zsh, curl, jq, and git..."
    sudo apt update && sudo apt install -y zsh curl jq git
}

# Function to install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "Oh My Zsh is already installed!"
    fi
}

# Function to set Zsh as default shell
set_default_shell() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Setting Zsh as the default shell..."
        chsh -s "$(which zsh)"
    fi
}

# Function to securely store API key
set_api_key() {
    echo "Enter your OpenAI API key: "
    read -s API_KEY
    if [[ -n "$API_KEY" ]]; then
        echo "export OPENAI_API_KEY=\"$API_KEY\"" | tee -a "$ZSHRC" "$BASHRC"
        echo "API key saved securely in ~/.zshrc and ~/.bashrc"
    else
        echo "No API key entered. Skipping..."
    fi
}

# Function to download or update ChatGPT shell script
install_chatgpt_shell() {
    echo "Downloading ChatGPT shell script..."
    curl -sL "$SCRIPT_URL" -o "$HOME/.chatgpt_shell.sh"
    chmod +x "$HOME/.chatgpt_shell.sh"

    # Add alias if not already present
    if ! grep -q 'alias ai=' "$ZSHRC"; then
        echo 'alias ai="~/.chatgpt_shell.sh"' | tee -a "$ZSHRC" "$BASHRC"
    fi
}

# Function to check for script updates
update_script() {
    echo "Checking for updates..."

    TMP_FILE=$(mktemp)  # Create a temporary file for the update
    curl -sL "$INSTALL_SCRIPT_URL" -o "$TMP_FILE"

    if ! cmp -s "$TMP_FILE" "$0"; then
        echo "New update found!"
        echo "Downloading the updated script..."
        mv "$TMP_FILE" "$HOME/.chatgpt_install_latest.sh"
        chmod +x "$HOME/.chatgpt_install_latest.sh"
        echo "Update complete. Please run the new script manually:"
        echo "bash \$HOME/.chatgpt_install_latest.sh"
        exit 0
    else
        echo "Already up to date!"
        rm "$TMP_FILE"
    fi
}




# Run installation steps
install_dependencies
install_oh_my_zsh
set_default_shell
install_chatgpt_shell
set_api_key
update_script

# Reload shell configuration
echo "Reloading shell..."
source "$ZSHRC" || source "$BASHRC"

echo "Installation complete! Restart your terminal or run 'exec zsh' to apply changes."

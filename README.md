# ChatGPT CLI for Windows, Linux, and macOS

This repository provides a **command-line interface (CLI) for ChatGPT**, allowing users to interact with OpenAI's GPT models directly from the terminal. It supports:
- **Windows (PowerShell, CMD, Windows Terminal)**
- **Linux (Bash, Zsh, Terminal, SSH)**

## 🚀 Features
✅ Securely stores **OpenAI API Key**  
✅ Works in **PowerShell, CMD, and Linux Shells**  
✅ **Interactive Mode** (ChatGPT session in the terminal)  
✅ **Single Query Mode** (Run AI-powered commands instantly)  
✅ **Supports executing AI-suggested commands**  
✅ **Auto-updates** for the latest version  

---

# 📌 Installation

## 🔹 Windows (PowerShell & CMD)
1. **Open PowerShell** (Run as Administrator recommended).
2. **Run this one-liner to install:**
   irm https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/install.ps1 | iex
3. After installation, restart PowerShell or run:
. $PROFILE

✅ Alternative Installation (Manual)
1. Clone the repository:
git clone https://github.com/mrcrunchybeans/zsh-chatgpt.git
cd zsh-chatgpt
2. Run the installer:
.\install.ps1
3. Restart PowerShell.

🔹 Linux (Bash & Zsh)
✅ Quick Install
Run this command in your terminal:
bash <(curl -sL https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/install.sh)

✅ Manual Installation
1. Clone the repository:
git clone https://github.com/mrcrunchybeans/zsh-chatgpt.git
cd zsh-chatgpt
2. Run the installer:
bash install.sh
3. Restart your shell:
exec zsh || exec bash

🔑 Setting Your OpenAI API Key
After installation, you must set your OpenAI API Key for the script to work.

Windows:
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-api-key-here", "User")

Linux:
export OPENAI_API_KEY="your-api-key-here"
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.bashrc  # For Bash users
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.zshrc   # For Zsh users
source ~/.bashrc || source ~/.zshrc


⚡ Usage
🔹 Windows (PowerShell & CMD)
Once installed, you can call ChatGPT using:

Single Query Mode:
ai "How do I list all files in a folder in PowerShell?"

Interactive Mode:
ai
Then, type queries interactively.

🔹 Linux (Bash & Zsh)
Single Query Mode:
ai "How do I find large files in Linux?"

Interactive Mode:
ai
Then, type queries interactively.

🔄 Updating to the Latest Version
Windows:
irm https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/install.ps1 | iex

Linux:
bash <(curl -sL https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/install.sh)

❓ Troubleshooting
🔹 Windows
If ai is not recognized, restart PowerShell or run:
. $PROFILE

If PowerShell execution is restricted, enable script execution:
Set-ExecutionPolicy Bypass -Scope Process -Force

🔹 Linux
If ai is not found, check that it’s in your $PATH or re-run:
source ~/.bashrc || source ~/.zshrc

📜 License
This project is open-source and licensed under the MIT License.

❤️ Contributing
Feel free to submit pull requests, bug reports, and feature suggestions!
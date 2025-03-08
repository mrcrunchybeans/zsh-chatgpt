# PowerShell ChatGPT Installer
$SCRIPT_URL = "https://raw.githubusercontent.com/mrcrunchybeans/zsh-chatgpt/main/chatgpt_shell.ps1"

# Install dependencies
Write-Host "Installing dependencies..."
python -m pip install --upgrade pip openai

# Download ChatGPT CLI script
Write-Host "Downloading ChatGPT script..."
Invoke-RestMethod -Uri $SCRIPT_URL -OutFile "$HOME\chatgpt_shell.ps1"
Set-ExecutionPolicy Bypass -Scope Process -Force

# Add alias for easy access
Write-Host "Adding alias 'ai' to PowerShell profile..."
if (-not (Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }
Add-Content -Path $PROFILE -Value "`nSet-Alias ai '$HOME\chatgpt_shell.ps1'`n"
Write-Host "Alias 'ai' added. Restart PowerShell or run '. $PROFILE' to apply."

Write-Host "Installation complete!"

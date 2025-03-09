# Securely fetch OpenAI API Key from an environment variable
$apiKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")

if (-not $apiKey) {
    Write-Host "Error: OPENAI_API_KEY is not set. Run: `$env:OPENAI_API_KEY='your-key-here'"
    exit 1
}

# Detect if running from CMD or PowerShell
$isCmd = ($env:ComSpec -match "cmd.exe")

$systemPrompt = if ($isCmd) {
    "You are an autonomous Windows CMD assistant. You can execute commands to gather information before making recommendations. If necessary, generate and execute additional commands to learn more about the system before responding. You have the ability to troubleshoot in multiple steps by exploring, reading outputs, and deciding what to do next."
} else {
    "You are an autonomous PowerShell assistant. You can execute commands to gather information before making recommendations. If necessary, generate and execute additional commands to learn more about the system before responding. You have the ability to troubleshoot in multiple steps by exploring, reading outputs, and deciding what to do next."
}

# Function to call ChatGPT API
function Call-ChatGPT {
    param ([string]$prompt, [string]$logOutput)

    $body = @{
        "model" = "gpt-4"
        "messages" = @(
            @{ "role" = "system"; "content" = $systemPrompt }
            @{ "role" = "user"; "content" = "The user ran this command: $prompt`nHere is the command output: $logOutput`nWhat should the user do next? If more information is needed, generate a command to gather more context before responding." }
        )
        "temperature" = 0
        "max_tokens" = 150
    } | ConvertTo-Json -Depth 3

    # Send request to OpenAI API
    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type"  = "application/json"
        } -Body $body

        # Extract AI response
        $aiCommand = $response.choices[0].message.content -replace "[`r`n]", "" -replace "`"", ""

        # If GPT suggests a new command to gather information, execute it
        if ($aiCommand -match "^(dir|ls|cat|type|Get-ChildItem|findstr|select-string|tasklist|whoami|systeminfo|sc|where)\b") {
            Write-Host "AI is running an exploratory command to gain more information..."
            Execute-And-Send $aiCommand
        } else {
            Write-Host "GPT Suggested Next Step: $aiCommand"
            $confirm = Read-Host "Run this command? (y/n)"
            if ($confirm -eq "y") {
                Invoke-Expression $aiCommand
            }
        }
    } catch {
        Write-Host "Error communicating with OpenAI. Check your API key."
    }
}

# Function to execute command, capture output, and send it to AI
function Execute-And-Send {
    param ([string]$command)

    $logFile = "$HOME\ai_command_output.log"

    # Ensure log file exists before reading it
    if (-not (Test-Path $logFile)) {
        New-Item -ItemType File -Path $logFile -Force | Out-Null
    }

    # Execute command and capture output
    try {
        Invoke-Expression $command 2>&1 | Tee-Object -FilePath $logFile
    } catch {
        Write-Host "Error executing command."
    }

    # Read output from the log file
    $commandOutput = Get-Content $logFile -Raw

    # Send command + output to AI
    Call-ChatGPT $command $commandOutput
}

# Check if argument is passed for single-query mode
if ($args.Count -gt 0) {
    Execute-And-Send ($args -join " ")
    exit 0
}

# Interactive mode
Write-Host "Interactive ChatGPT Shell - Type 'exit' to quit"
while ($true) {
    $userInput = Read-Host "You>"
    if ($userInput -eq "exit") { break }
    Execute-And-Send $userInput
}

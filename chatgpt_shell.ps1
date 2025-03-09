# Check that the OPENAI_API_KEY environment variable is set
if (-not $env:OPENAI_API_KEY) {
    Write-Host "Error: OPENAI_API_KEY is not set. Run: `$env:OPENAI_API_KEY='your-key-here'" -ForegroundColor Red
    exit 1
}

# Define system prompt for ChatGPT (using plain ASCII characters)
$SYSTEM_PROMPT = "You are an advanced Windows PowerShell AI assistant. The user will ask for a task, and you must return a valid, executable PowerShell command. Always treat the full user query as a single request. If the user asks for files, use 'Get-ChildItem' or 'dir' appropriately. Never return explanations, comments, or text - only return a correctly formatted PowerShell command."

# Global variables to store the last command and its output
$global:LAST_COMMAND = ""
$global:LAST_OUTPUT = ""

function Call-ChatGPT {
    param (
        [string]$prompt
    )

    $max_retries = 5
    $attempt = 0
    $RESPONSE = ""

    while ([string]::IsNullOrEmpty($RESPONSE) -or $RESPONSE -eq "null" -or $RESPONSE -match "error") {
        if ($attempt -ge $max_retries) {
            Write-Host "GPT failed to generate a valid command after $max_retries attempts."
            Write-Host "Generating a default 'Get-ChildItem' command instead."
            $RESPONSE = "Get-ChildItem -Path C:\ -Filter '*.mp4' -Recurse -ErrorAction SilentlyContinue"
            break
        }

        # Build the JSON payload using a hashtable and ConvertTo-Json
        $jsonPayload = @{
            model    = "gpt-4"
            messages = @(
                @{ role = "system"; content = $SYSTEM_PROMPT },
                @{ role = "user"; content = "User input: $prompt. Last executed command: $global:LAST_COMMAND. Output of last command: $global:LAST_OUTPUT. Based on this, return only a valid PowerShell command, formatted properly. If uncertain, default to using 'Get-ChildItem' with reasonable assumptions." }
            )
            temperature = 0
            max_tokens  = 100
        } | ConvertTo-Json

        try {
            $responseJson = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers @{
                "Content-Type"  = "application/json"
                "Authorization" = "Bearer $($env:OPENAI_API_KEY)"
            } -Body $jsonPayload
            $RESPONSE = $responseJson.choices[0].message.content.Trim()
        }
        catch {
            Write-Host "Error calling API: $_"
        }

        $attempt++
    }

    Write-Host "GPT Suggested Command: $RESPONSE"

    # Define allowed commands (adjust as needed)
    if ($RESPONSE -match "^(Get-ChildItem|Get-Content|Get-Process|whoami|hostname|ipconfig|netstat|Get-Service|Select-String)") {
        # If the command appears to search from the root (e.g. "Get-ChildItem -Path C:\"), ask for confirmation.
        if ($RESPONSE -match "^Get-ChildItem\s+-Path\s+C:\\") {
            $confirmRoot = Read-Host "This command will search from the root directory and may take a long time. Run this command? (y/n)"
            if ($confirmRoot -ne "y") {
                Write-Host "Command aborted."
                return
            }
        }
        Write-Host "AI is running an exploratory command..."
        Execute-Command $RESPONSE
    }
    else {
        $confirm = Read-Host "Run this command? (y/n)"
        if ($confirm -eq "y") {
            Execute-Command $RESPONSE
        }
    }
}

function Execute-Command {
    param (
        [string]$command
    )
    $global:LAST_COMMAND = $command
    try {
        # Execute the command and capture its output (including errors)
        $global:LAST_OUTPUT = Invoke-Expression $command 2>&1
        Write-Output $global:LAST_OUTPUT
    }
    catch {
        Write-Host "Error executing command: $_"
    }
}

# Single-query mode: if arguments are provided, execute the query and exit
if ($args.Count -gt 0) {
    $inputPrompt = $args -join " "
    Call-ChatGPT $inputPrompt
    exit
}

# Interactive mode
Write-Host "Interactive ChatGPT Shell - Type 'exit' to quit"
while ($true) {
    $userInput = Read-Host "You>"
    if ($userInput -eq "exit") { break }
    Call-ChatGPT $userInput
}

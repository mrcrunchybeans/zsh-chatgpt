# Securely fetch OpenAI API Key from an environment variable
$apiKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")

if (-not $apiKey) {
    Write-Host "Error: OPENAI_API_KEY is not set. Run: `$env:OPENAI_API_KEY='your-key-here'"
    exit 1
}

# Function to call ChatGPT API
function Call-ChatGPT {
    param ([string]$prompt)

    # Create API request body
    $body = @{
        "model" = "gpt-4"
        "messages" = @(
            @{ "role" = "system"; "content" = "You are an AI that provides Windows PowerShell commands. Output only the command, without explanations." }
            @{ "role" = "user"; "content" = $prompt }
        )
    } | ConvertTo-Json -Depth 3

    # Send request to OpenAI API
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    } -Body $body

    # Extract and display AI response
    $aiCommand = $response.choices[0].message.content
    Write-Host "GPT Suggested Command: " $aiCommand

    # Ask if the user wants to execute the command
    $confirm = Read-Host "Run this command? (y/n)"
    if ($confirm -eq "y") {
        Invoke-Expression $aiCommand
    }
}

# Check if argument is passed for single-query mode
if ($args.Count -gt 0) {
    Call-ChatGPT ($args -join " ")
    exit 0
}

# Interactive mode
Write-Host "Interactive ChatGPT Shell - Type 'exit' to quit"
while ($true) {
    $userInput = Read-Host "You>"
    if ($userInput -eq "exit") { break }
    Call-ChatGPT $userInput
}

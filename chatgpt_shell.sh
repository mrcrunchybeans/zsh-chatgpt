#!/bin/bash

# Securely fetch OpenAI API Key from an environment variable
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY is not set. Run: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Define system prompt for ChatGPT
SYSTEM_PROMPT="You are an autonomous Linux shell assistant. You can execute commands to gather information before making recommendations. If necessary, generate and execute additional commands to learn more about the system before responding. You have the ability to troubleshoot in multiple steps by exploring, reading outputs, and deciding what to do next."

# Function to call ChatGPT API
call_chatgpt() {
    local prompt="$1"
    local logOutput="$2"

    # Create API request JSON
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "{
        \"model\": \"gpt-4\",
        \"messages\": [
          {\"role\": \"system\", \"content\": \"$SYSTEM_PROMPT\"},
          {\"role\": \"user\", \"content\": \"The user ran this command: $prompt\nHere is the command output: $logOutput\nWhat should the user do next? If more information is needed, generate a command to gather more context before responding.\"}
        ],
        \"temperature\": 0,
        \"max_tokens\": 150
      }" | jq -r '.choices[0].message.content')

    echo "GPT Suggested Next Step: $RESPONSE"

    # If AI suggests an exploratory command, execute it
    if [[ "$RESPONSE" =~ ^(ls|cat|find|grep|df|ps|whoami|hostnamectl|ip|netstat) ]]; then
        echo "AI is running an exploratory command..."
        execute_and_send "$RESPONSE"
    else
        read -p "Run this command? (y/n): " CONFIRM
        if [[ "$CONFIRM" == "y" ]]; then
            eval "$RESPONSE"
        fi
    fi
}

# Function to execute command, capture output, and send it to AI
execute_and_send() {
    local command="$1"
    local logFile="$HOME/ai_command_output.log"

    # Ensure log file exists before reading it
    touch "$logFile"

    # Execute command and capture output
    eval "$command" 2>&1 | tee "$logFile"

    # Read output from the log file
    local commandOutput
    commandOutput=$(cat "$logFile")

    # Send command + output to AI
    call_chatgpt "$command" "$commandOutput"
}

# Check if argument is passed for single-query mode
if [[ -n "$1" ]]; then
    execute_and_send "$1"
    exit 0
fi

# Interactive mode
echo "Interactive ChatGPT Shell - Type 'exit' to quit"
while true; do
    read -p "You> " USER_INPUT
    [[ "$USER_INPUT" == "exit" ]] && break
    execute_and_send "$USER_INPUT"
done

#!/bin/bash

# Securely fetch OpenAI API Key from an environment variable
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY is not set. Run: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Define system prompt for ChatGPT
SYSTEM_PROMPT="You are an advanced Linux AI assistant. The user will ask for a task, and you must return a valid, executable Linux command. Never return explanations, comments, or text—only return a correctly formatted shell command."

# Function to call ChatGPT API
call_chatgpt() {
    local prompt="$1"
    local logOutput="$2"
    local max_retries=3
    local attempt=0
    local RESPONSE=""

    while [[ -z "$RESPONSE" || "$RESPONSE" == "null" || "$RESPONSE" =~ "find: " || "$RESPONSE" =~ "error" ]]; do
        if [[ $attempt -ge $max_retries ]]; then
            echo "GPT failed to generate a valid command after $max_retries attempts."
            return
        fi

        RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $OPENAI_API_KEY" \
          -d "{
            \"model\": \"gpt-4\",
            \"messages\": [
              {\"role\": \"system\", \"content\": \"$SYSTEM_PROMPT\"},
              {\"role\": \"user\", \"content\": \"User input: '$prompt'. Based on this request, return only a valid shell command. Never output explanations, formatting, or extra text.\"}
            ],
            \"temperature\": 0,
            \"max_tokens\": 100
          }" | jq -r '.choices[0].message.content')

        ((attempt++))
    done

    echo "GPT Suggested Next Step: $RESPONSE"

    # If AI suggests an exploratory command, execute it
    if [[ "$RESPONSE" =~ ^(ls|cat|find|grep|df|ps|whoami|hostnamectl|ip|netstat|which) ]]; then
        echo "AI is running an exploratory command..."
        execute_and_send "$RESPONSE"
    else
        read -p "Run this command? (y/n): " CONFIRM
        if [[ "$CONFIRM" == "y" ]]; then
            eval "$RESPONSE"
        fi
    fi
}

# Function to clean up user input before sending it to GPT
sanitize_input() {
    local input="$1"

    # Convert common phrases into structured queries
    input=$(echo "$input" | sed -E 's/find my /find /gI')
    input=$(echo "$input" | sed -E 's/in docker volumes/ -path "/var/lib/docker/volumes/*"/gI')

    echo "$input"
}

# Function to execute command, capture output, and send it to AI
execute_and_send() {
    local raw_command="$1"
    local command
    command=$(sanitize_input "$raw_command")
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

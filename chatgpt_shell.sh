#!/bin/bash

# Securely fetch OpenAI API Key from an environment variable
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY is not set. Run: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Define system prompt for ChatGPT (all on one line)
SYSTEM_PROMPT="You are an advanced Linux AI assistant. The user will ask for a task, and you must return a valid, executable Linux command. Always treat the full user query as a single request. If the user asks for files, use the 'find' or 'ls' command appropriately. Never return explanations, comments, or text—only return a correctly formatted shell command."

# Stores the last command and its output in memory
LAST_COMMAND=""
LAST_OUTPUT=""

# Function to call ChatGPT API
call_chatgpt() {
    local prompt="$1"
    local max_retries=5  # Increased retries to 5 for better success rates
    local attempt=0
    local RESPONSE=""

    while [[ -z "$RESPONSE" || "$RESPONSE" == "null" || "$RESPONSE" =~ "error" ]]; do
        if [[ $attempt -ge $max_retries ]]; then
            echo "GPT failed to generate a valid command after $max_retries attempts."
            echo "Generating a default 'find' command instead."
            RESPONSE='find / -iname "*.mp4" 2>/dev/null'
            break
        fi

        # Construct a safe JSON payload using jq
        json_payload=$(jq -n \
          --arg model "gpt-4" \
          --arg system_prompt "$SYSTEM_PROMPT" \
          --arg user_message "User input: $prompt. Last executed command: $LAST_COMMAND. Output of last command: $LAST_OUTPUT. Based on this, return only a valid Linux shell command, formatted properly. If uncertain, default to using 'find' with reasonable assumptions." \
          '{
            model: $model,
            messages: [
              {role: "system", content: $system_prompt},
              {role: "user", content: $user_message}
            ],
            temperature: 0,
            max_tokens: 100
          }')

        RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $OPENAI_API_KEY" \
          -d "$json_payload" | jq -r '.choices[0].message.content')

        ((attempt++))
    done

    echo "GPT Suggested Command: $RESPONSE"

    # Auto-execute if command starts with one of the allowed prefixes
    if [[ "$RESPONSE" =~ ^(ls|cat|find|grep|df|ps|whoami|hostnamectl|ip|netstat|which) ]]; then
        echo "AI is running an exploratory command..."
        execute_command "$RESPONSE"
    else
        read -p "Run this command? (y/n): " CONFIRM
        if [[ "$CONFIRM" == "y" ]]; then
            eval "$RESPONSE"
        fi
    fi
}

# Function to execute command and keep output in memory
execute_command() {
    local command="$1"
    LAST_COMMAND="$command"

    # Capture command output (stderr merged) in LAST_OUTPUT
    LAST_OUTPUT=$(eval "$command" 2>&1)
    echo "$LAST_OUTPUT"
}

# Single-query mode: if an argument is provided, execute it and exit
if [[ -n "$1" ]]; then
    call_chatgpt "$1"
    exit 0
fi

# Interactive mode
echo "Interactive ChatGPT Shell - Type 'exit' to quit"
while true; do
    read -p "You> " USER_INPUT
    [[ "$USER_INPUT" == "exit" ]] && break
    call_chatgpt "$USER_INPUT"
done

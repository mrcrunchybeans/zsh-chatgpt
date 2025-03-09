#!/bin/bash

# Securely fetch OpenAI API Key from an environment variable
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY is not set. Run: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Define system prompt for ChatGPT
SYSTEM_PROMPT="You are an advanced Linux AI assistant. The user will ask for a task, and you must return a valid, executable Linux command.
Always treat the full user query as a single request. If the user asks for files, use the 'find' or 'ls' command appropriately.
Never return explanations, comments, or text—only return a correctly formatted shell command."

# Stores the last command output in memory
LAST_COMMAND=""
LAST_OUTPUT=""

# Function to call ChatGPT API
call_chatgpt() {
    local prompt="$1"
    local command_output="$2"
    local max_retries=5  # Increased retries to 5 for better success rates
    local attempt=0
    local RESPONSE=""

    while [[ -z "$RESPONSE" || "$RESPONSE" == "null" || "$RESPONSE" =~ "error" || "$RESPONSE" == "" ]]; do
        if [[ $attempt -ge $max_retries ]]; then
            echo "GPT failed to generate a valid command after $max_retries attempts."
            echo "Generating a default 'find' command instead."
            RESPONSE="find / -iname \"*.mp4\" 2>/dev/null"
            break
        fi

        RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $OPENAI_API_KEY" \
          -d "{
            \"model\": \"gpt-4\",
            \"messages\": [
              {\"role\": \"system\", \"content\": \"$SYSTEM_PROMPT\"},
              {\"role\": \"user\", \"content\": \"User input: '$prompt'.
              Last executed command: '$LAST_COMMAND'.
              Output of last command: '$LAST_OUTPUT'.
              Based on this, return only a valid Linux shell command, formatted properly.
              If uncertain, default to using 'find' with reasonable assumptions.\"}
            ],
            \"temperature\": 0,
            \"max_tokens\": 100
          }" | jq -r '.choices[0].message.content')

        ((attempt++))
    done

    echo "GPT Suggested Command: $RESPONSE"

    # Ensure AI suggests a valid command before execution
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

    # Capture output in memory instead of a file
    LAST_OUTPUT=$(eval "$command" 2>&1)

    # Display the output as usual
    echo "$LAST_OUTPUT"
}

# Check if argument is passed for single-query mode
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

#!/bin/bash

# Securely fetch OpenAI API Key from an environment variable
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY is not set. Run: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Function to call ChatGPT API
call_chatgpt() {
    local prompt="$1"

    # Send request to OpenAI API
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "{
        \"model\": \"gpt-4\",
        \"messages\": [{\"role\": \"system\", \"content\": \"You are an AI that provides Linux terminal commands. Output only the command, without explanations.\"},
                      {\"role\": \"user\", \"content\": \"$prompt\"}]
      }" | jq -r '.choices[0].message.content')

    echo "GPT Suggested Command: $RESPONSE"

    # Ask if the user wants to execute the command
    read -p "Run this command? (y/n): " CONFIRM
    if [[ $CONFIRM == "y" ]]; then
        eval "$RESPONSE"
    fi
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
    [[ "$USER_INPUT" == "exit" ]] && break  # Exit on user command
    call_chatgpt "$USER_INPUT"
done

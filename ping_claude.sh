#!/bin/bash

# Claude Ping Script
# Sends a ping to Claude in headless mode and logs the response

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

# Read log file path from config
LOG_FILE=$(jq -r '.log_file' "$CONFIG_FILE" 2>/dev/null || echo "~/Library/Logs/claude_ping.log")
LOG_FILE="${LOG_FILE/#\~/$HOME}"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Starting Claude ping..." >> "$LOG_FILE"

# Send ping to Claude in headless mode
RESPONSE=$(echo "ping" | claude -p "Когда я тебе посылаю команду ping, отвечай одним словом ping" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "[$TIMESTAMP] SUCCESS: $RESPONSE" >> "$LOG_FILE"
    echo "Claude ping successful: $RESPONSE"
else
    echo "[$TIMESTAMP] ERROR: $RESPONSE" >> "$LOG_FILE"
    echo "Claude ping failed: $RESPONSE" >&2
fi

echo "[$TIMESTAMP] Claude ping completed" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
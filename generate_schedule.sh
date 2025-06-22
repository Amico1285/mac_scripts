#!/bin/bash

# Generate launchd schedule based on config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
PING_SCRIPT="$SCRIPT_DIR/ping_claude.sh"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install with: brew install jq"
    exit 1
fi

# Read start hour from config
START_HOUR=$(jq -r '.start_hour' "$CONFIG_FILE" 2>/dev/null)
if [ "$START_HOUR" = "null" ] || [ -z "$START_HOUR" ]; then
    echo "Error: start_hour not found in config.json"
    exit 1
fi

# Validate start hour
if ! [[ "$START_HOUR" =~ ^[0-9]+$ ]] || [ "$START_HOUR" -lt 0 ] || [ "$START_HOUR" -gt 23 ]; then
    echo "Error: start_hour must be between 0 and 23"
    exit 1
fi

echo "Generating schedule for start hour: $START_HOUR"

# Calculate all 4 ping times
TIMES=()
CURRENT_HOUR=$START_HOUR
CURRENT_MINUTE=0

for i in {1..4}; do
    TIMES+=("$(printf "%02d:%02d" $CURRENT_HOUR $CURRENT_MINUTE)")
    
    # Add 5 hours 1 minute for next ping
    CURRENT_MINUTE=$((CURRENT_MINUTE + 1))
    CURRENT_HOUR=$((CURRENT_HOUR + 5))
    
    # Handle day overflow
    if [ $CURRENT_HOUR -ge 24 ]; then
        CURRENT_HOUR=$((CURRENT_HOUR - 24))
    fi
done

echo "Ping times will be: ${TIMES[*]}"

# Create launchd plist files
PLIST_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$PLIST_DIR"

for i in {0..3}; do
    PING_NUM=$((i + 1))
    TIME=${TIMES[$i]}
    HOUR=${TIME%%:*}
    MINUTE=${TIME##*:}
    
    PLIST_FILE="$PLIST_DIR/com.user.claude-ping-$PING_NUM.plist"
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.claude-ping-$PING_NUM</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$PING_SCRIPT</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>$HOUR</integer>
        <key>Minute</key>
        <integer>$MINUTE</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

    echo "Created: $PLIST_FILE for time $TIME"
done

echo ""
echo "Schedule generated successfully!"
echo "Run './install.sh' to activate the schedule."
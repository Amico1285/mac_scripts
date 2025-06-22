#!/bin/bash

# Install Claude Ping System

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

echo "🚀 Installing Claude Ping System..."

# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "❌ Error: Claude CLI not found. Please install Claude Code first."
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq..."
    if command -v brew &> /dev/null; then
        brew install jq
    else
        echo "❌ Error: jq is required. Please install Homebrew first, then run: brew install jq"
        exit 1
    fi
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/ping_claude.sh"
chmod +x "$SCRIPT_DIR/generate_schedule.sh"
chmod +x "$SCRIPT_DIR/uninstall.sh"
chmod +x "$SCRIPT_DIR/setup_wake.sh"

# Generate schedule
echo "📅 Generating schedule..."
"$SCRIPT_DIR/generate_schedule.sh"

if [ $? -ne 0 ]; then
    echo "❌ Error generating schedule"
    exit 1
fi

# Load launchd services
echo "🔄 Loading launchd services..."
PLIST_DIR="$HOME/Library/LaunchAgents"

for i in {1..4}; do
    PLIST_FILE="$PLIST_DIR/com.user.claude-ping-$i.plist"
    if [ -f "$PLIST_FILE" ]; then
        launchctl load "$PLIST_FILE"
        echo "✅ Loaded ping service $i"
    fi
done

# Setup wake configuration
echo "⏰ Setting up wake configuration..."
"$SCRIPT_DIR/setup_wake.sh"

# Create log directory
LOG_FILE=$(jq -r '.log_file' "$CONFIG_FILE" 2>/dev/null || echo "~/Library/Logs/claude_ping.log")
LOG_FILE="${LOG_FILE/#\~/$HOME}"
mkdir -p "$(dirname "$LOG_FILE")"

echo ""
echo "✅ Claude Ping System installed successfully!"
echo ""
echo "📋 Configuration:"
START_HOUR=$(jq -r '.start_hour' "$CONFIG_FILE")
echo "   Start time: $(printf "%02d:00" $START_HOUR)"
echo "   Log file: $LOG_FILE"
echo ""
echo "📝 To change start time:"
echo "   1. Edit config.json"
echo "   2. Run ./generate_schedule.sh"
echo "   3. Run ./install.sh again"
echo ""
echo "🗑️  To uninstall: ./uninstall.sh"
echo "📊 To view logs: tail -f '$LOG_FILE'"
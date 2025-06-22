#!/bin/bash

# Uninstall Claude Ping System

echo "🗑️  Uninstalling Claude Ping System..."

PLIST_DIR="$HOME/Library/LaunchAgents"

# Unload and remove launchd services
for i in {1..4}; do
    PLIST_FILE="$PLIST_DIR/com.user.claude-ping-$i.plist"
    if [ -f "$PLIST_FILE" ]; then
        echo "🔄 Unloading ping service $i..."
        launchctl unload "$PLIST_FILE" 2>/dev/null
        rm "$PLIST_FILE"
        echo "✅ Removed ping service $i"
    fi
done

echo ""
echo "✅ Claude Ping System uninstalled successfully!"
echo ""
echo "📝 Note: Log files and wake settings were preserved."
echo "   Log location: ~/Library/Logs/claude_ping.log"
echo "   Wake settings: Check System Preferences > Energy Saver"
#!/bin/bash

# Setup Mac wake configuration for Claude Ping

echo "⏰ Setting up Mac wake configuration..."

# Check if running with sudo (needed for some pmset commands)
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Warning: Running as root. Some settings may affect system-wide power management."
fi

# Configure power management settings
echo "🔧 Configuring power management..."

# Allow wake for network access (needed for network-based scheduling)
sudo pmset -a womp 1 2>/dev/null || echo "⚠️  Could not set womp (Wake on Magic Packet)"

# Allow wake from sleep for scheduled events
sudo pmset -a sleep 0 2>/dev/null || echo "⚠️  Could not disable automatic sleep"

# Schedule daily wake at 4:59 AM (1 minute before first ping)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
    START_HOUR=$(jq -r '.start_hour' "$CONFIG_FILE" 2>/dev/null)
    if [ "$START_HOUR" != "null" ] && [ -n "$START_HOUR" ]; then
        # Calculate wake time (1 minute before start)
        WAKE_HOUR=$START_HOUR
        WAKE_MINUTE=59
        
        if [ $START_HOUR -eq 0 ]; then
            WAKE_HOUR=23
            WAKE_MINUTE=59
        else
            WAKE_HOUR=$((START_HOUR - 1))
        fi
        
        WAKE_TIME=$(printf "%02d:%02d:00" $WAKE_HOUR $WAKE_MINUTE)
        
        echo "⏰ Setting daily wake time to $WAKE_TIME..."
        
        # Schedule repeating wake
        sudo pmset repeat wakeorpoweron MTWRFSU $WAKE_TIME 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ Daily wake scheduled for $WAKE_TIME"
        else
            echo "⚠️  Could not schedule automatic wake. You may need to configure this manually in System Preferences > Energy Saver."
        fi
    fi
fi

echo ""
echo "📋 Current power management settings:"
pmset -g sched 2>/dev/null || echo "No scheduled wake events found"

echo ""
echo "💡 Manual configuration tips:"
echo "   1. Go to System Preferences > Energy Saver"
echo "   2. Enable 'Wake for Wi-Fi network access'"
echo "   3. Consider disabling 'Put hard disks to sleep when possible'"
echo "   4. Set 'Computer sleep' to 'Never' if you want guaranteed execution"
echo ""
echo "⚠️  Note: Some wake settings require administrator privileges."
echo "   If scheduling failed, you can manually set wake times in System Preferences."
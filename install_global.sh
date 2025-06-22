#!/bin/bash

# Install CloudPing globally

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDEPING_SCRIPT="$SCRIPT_DIR/claudeping"
INSTALL_PATH="/usr/local/bin/claudeping"

echo "🚀 Installing ClaudePing globally..."

# Check if claudeping script exists
if [ ! -f "$CLAUDEPING_SCRIPT" ]; then
    echo "❌ Error: claudeping script not found in $SCRIPT_DIR"
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
sudo mkdir -p /usr/local/bin

# Remove existing symlink if it exists
if [ -L "$INSTALL_PATH" ]; then
    echo "🗑️  Removing existing installation..."
    sudo rm "$INSTALL_PATH"
fi

# Create symlink
echo "🔗 Creating global command..."
sudo ln -s "$CLAUDEPING_SCRIPT" "$INSTALL_PATH"

if [ $? -eq 0 ]; then
    echo "✅ ClaudePing installed successfully!"
    echo ""
    echo "You can now run 'claudeping' from anywhere in your terminal."
    echo ""
    echo "📋 Usage:"
    echo "   claudeping    - Open interactive manager"
    echo ""
    echo "🔧 The command will use the configuration from:"
    echo "   $SCRIPT_DIR"
else
    echo "❌ Installation failed"
    exit 1
fi
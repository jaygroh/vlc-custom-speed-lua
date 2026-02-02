#!/bin/bash
#
# Install script for VLC Custom Speed Calculator extension
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_FILE="$SCRIPT_DIR/custom_speed.lua"

# Detect OS and set install path
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_DIR="$HOME/.local/share/vlc/lua/extensions"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_DIR="$HOME/Library/Application Support/org.videolan.vlc/lua/extensions"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    INSTALL_DIR="$APPDATA/vlc/lua/extensions"
else
    echo "Unknown OS: $OSTYPE"
    echo "Please manually copy custom_speed.lua to your VLC extensions folder"
    exit 1
fi

echo "VLC Custom Speed Calculator - Installation"
echo "==========================================="
echo ""
echo "Source: $EXTENSION_FILE"
echo "Destination: $INSTALL_DIR"
echo ""

# Check if extension file exists
if [[ ! -f "$EXTENSION_FILE" ]]; then
    echo "Error: custom_speed.lua not found in script directory"
    exit 1
fi

# Create directory if needed
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "Creating extensions directory..."
    mkdir -p "$INSTALL_DIR"
fi

# Copy extension
echo "Installing extension..."
cp "$EXTENSION_FILE" "$INSTALL_DIR/"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart VLC if it's running"
echo "  2. Play a video"
echo "  3. Go to View -> Custom Speed Calculator"
echo ""

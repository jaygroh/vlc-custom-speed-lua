#!/bin/bash
#
# Install script for VLC Custom Speed Calculator extension
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS and set install paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    EXT_DIR="$HOME/.local/share/vlc/lua/extensions"
    INTF_DIR="$HOME/.local/share/vlc/lua/intf"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    EXT_DIR="$HOME/Library/Application Support/org.videolan.vlc/lua/extensions"
    INTF_DIR="$HOME/Library/Application Support/org.videolan.vlc/lua/intf"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    EXT_DIR="$APPDATA/vlc/lua/extensions"
    INTF_DIR="$APPDATA/vlc/lua/intf"
else
    echo "Unknown OS: $OSTYPE"
    echo "Please manually copy the files:"
    echo "  custom_speed.lua -> VLC extensions folder"
    echo "  custom_speed_intf.lua -> VLC intf folder"
    exit 1
fi

echo "VLC Custom Speed Calculator - Installation"
echo "==========================================="
echo ""

# Create directories
mkdir -p "$EXT_DIR"
mkdir -p "$INTF_DIR"

# Install extension
echo "Installing extension..."
cp "$SCRIPT_DIR/custom_speed.lua" "$EXT_DIR/"
echo "  -> $EXT_DIR/custom_speed.lua"

# Install interface script
echo "Installing interface script..."
cp "$SCRIPT_DIR/custom_speed_intf.lua" "$INTF_DIR/"
echo "  -> $INTF_DIR/custom_speed_intf.lua"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart VLC if it's running"
echo "  2. Play a video"
echo "  3. Go to View -> Custom Speed Calculator"
echo "  4. Use 'Interface Setup' to enable OSD display"
echo ""

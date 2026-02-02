#!/bin/bash
#
# Uninstall script for VLC Custom Speed Calculator extension
#

set -e

# Detect OS and set paths
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
    exit 1
fi

echo "VLC Custom Speed Calculator - Uninstallation"
echo "============================================="
echo ""

# Remove extension
if [[ -f "$EXT_DIR/custom_speed.lua" ]]; then
    rm "$EXT_DIR/custom_speed.lua"
    echo "Removed: $EXT_DIR/custom_speed.lua"
fi

# Remove interface script
if [[ -f "$INTF_DIR/custom_speed_intf.lua" ]]; then
    rm "$INTF_DIR/custom_speed_intf.lua"
    echo "Removed: $INTF_DIR/custom_speed_intf.lua"
fi

echo ""
echo "Uninstallation complete!"
echo "Note: You may need to disable the interface in VLC preferences"
echo "      or restart VLC to fully remove."

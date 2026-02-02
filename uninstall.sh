#!/bin/bash
#
# Uninstall script for VLC Custom Speed Calculator extension
#

set -e

# Detect OS and set install path
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_DIR="$HOME/.local/share/vlc/lua/extensions"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_DIR="$HOME/Library/Application Support/org.videolan.vlc/lua/extensions"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    INSTALL_DIR="$APPDATA/vlc/lua/extensions"
else
    echo "Unknown OS: $OSTYPE"
    exit 1
fi

EXTENSION_PATH="$INSTALL_DIR/custom_speed.lua"

echo "VLC Custom Speed Calculator - Uninstallation"
echo "============================================="
echo ""

if [[ -f "$EXTENSION_PATH" ]]; then
    echo "Removing: $EXTENSION_PATH"
    rm "$EXTENSION_PATH"
    echo ""
    echo "Uninstallation complete!"
    echo "Restart VLC to complete removal."
else
    echo "Extension not found at: $EXTENSION_PATH"
    echo "Nothing to uninstall."
fi

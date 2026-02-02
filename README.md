# VLC Custom Speed Calculator - Lua Extension

A VLC media player extension that calculates playback speed to finish a video in a specified time or by a specific clock time.

## Features

- **Finish In**: Enter a number of minutes and calculate the required playback speed
- **Finish By**: Select from a dropdown of clock times (in 5-minute increments) to see what speed is needed
- Speed is clamped to a sensible 1x-4x range
- Real-time display of remaining video time and current playback speed
- One-click speed application

## Installation

### Automatic (Linux)

```bash
./install.sh
```

### Manual Installation

Copy `custom_speed.lua` to your VLC extensions folder:

| OS | Path |
|----|------|
| **Linux** | `~/.local/share/vlc/lua/extensions/` |
| **macOS** | `~/Library/Application Support/org.videolan.vlc/lua/extensions/` |
| **Windows** | `%APPDATA%\vlc\lua\extensions\` |

Create the directory if it doesn't exist:

```bash
# Linux
mkdir -p ~/.local/share/vlc/lua/extensions/
cp custom_speed.lua ~/.local/share/vlc/lua/extensions/

# macOS
mkdir -p ~/Library/Application\ Support/org.videolan.vlc/lua/extensions/
cp custom_speed.lua ~/Library/Application\ Support/org.videolan.vlc/lua/extensions/

# Windows (PowerShell)
mkdir -Force "$env:APPDATA\vlc\lua\extensions"
copy custom_speed.lua "$env:APPDATA\vlc\lua\extensions\"
```

### Restart VLC

After copying the file, restart VLC for the extension to appear.

## Usage

1. Open VLC and play a video
2. Go to **View** menu → **Custom Speed Calculator**
3. Use the extension:

### Finish In Mode
- Enter the number of minutes you want the remaining video to finish in (1-600)
- Click **Calculate** to see the required speed
- Click **Apply Speed** to set VLC to that speed

### Finish By Mode
- Click the **Finish By** tab button
- Select a time from the dropdown (shows times where speed would be 1x-4x)
- Click **Apply Speed** to set VLC to that speed

### Other Controls
- **Refresh Times**: Update the dropdown with current times (useful if you've been watching for a while)
- **Close**: Close the dialog

## Speed Limits

The extension limits speeds to **1x - 4x** to maintain reasonable playback quality:
- Below 1x: Video would need to be slowed down (not useful for this purpose)
- Above 4x: Audio quality degrades significantly

## Compatibility

- VLC 2.1.0 and later (Lua extensions support)
- VLC 3.x recommended
- Works on Linux, macOS, and Windows

## License

GNU General Public License v2.0 or later

## Credits

- Author: Jay Groh
- Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>

Based on the Qt/C++ Custom Speed Dialog implementation for VLC.

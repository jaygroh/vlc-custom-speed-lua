# VLC Custom Speed Calculator

A VLC media player extension that calculates playback speed to finish a video in a specified time, with optional on-screen display of speed-adjusted remaining time.

## Features

### Speed Calculator
- **Finish In**: Enter minutes, calculate required playback speed
- **Finish By**: Select from clock times to see required speed
- Speed clamped to sensible 1x-4x range
- One-click speed application

### On-Screen Display (OSD)
- **Speed-adjusted remaining time**: Shows real-world time left (e.g., "~ 25:00 remaining")
- **Current speed**: Displays when not at 1x (e.g., "1.50x speed")
- **Estimated finish time**: Shows clock time when video will end (e.g., "Ends 3:45 PM")
- Configurable position (9 screen positions)
- Enable/disable individual elements

## Installation

### Automatic (Linux/macOS)

```bash
./install.sh
```

### Manual Installation

Copy files to your VLC folders:

| File | Destination |
|------|-------------|
| `custom_speed.lua` | `~/.local/share/vlc/lua/extensions/` |
| `custom_speed_intf.lua` | `~/.local/share/vlc/lua/intf/` |

**Paths by OS:**

| OS | Extensions | Interface |
|----|------------|-----------|
| Linux | `~/.local/share/vlc/lua/extensions/` | `~/.local/share/vlc/lua/intf/` |
| macOS | `~/Library/Application Support/org.videolan.vlc/lua/extensions/` | `.../lua/intf/` |
| Windows | `%APPDATA%\vlc\lua\extensions\` | `%APPDATA%\vlc\lua\intf\` |

**Restart VLC** after installation.

## Usage

### First Time Setup

1. Open VLC and play a video
2. Go to **View** → **Custom Speed Calculator**
3. You'll see the **Interface Setup** dialog
4. Check **"Enable interface script"** and click **Save**
5. **Restart VLC** for OSD to work

### Speed Calculator

1. Play a video
2. **View** → **Custom Speed Calculator** → **Speed Calculator**
3. **Finish In**: Enter minutes, click **Apply Speed**
4. **Finish By**: Select time from dropdown, click **Apply Speed**

### OSD Settings

1. **View** → **Custom Speed Calculator** → **OSD Settings**
2. Check **"Enable OSD Display"**
3. Choose which elements to show:
   - Speed-adjusted remaining time
   - Current playback speed
   - Estimated finish time
4. Select screen position
5. Click **Save**

## Menu Structure

```
View → Custom Speed Calculator
    ├── Speed Calculator    (calculate and apply speeds)
    ├── OSD Settings        (configure on-screen display)
    └── Interface Setup     (enable/disable background script)
```

## How It Works

The extension has two components:

1. **Extension** (`custom_speed.lua`): Provides the UI dialogs for calculating speeds and configuring settings

2. **Interface Script** (`custom_speed_intf.lua`): Runs in background, displays OSD. Must be enabled via Interface Setup.

Settings are shared between components via VLC's bookmark10 config.

## Speed Limits

Speeds are limited to **1x - 4x**:
- Below 1x: Would slow down playback (not useful for this purpose)
- Above 4x: Audio quality degrades significantly

## Compatibility

- VLC 2.1.0+ (Lua extensions support)
- VLC 3.x recommended
- Linux, macOS, Windows

## Uninstall

```bash
./uninstall.sh
```

Or manually delete:
- `~/.local/share/vlc/lua/extensions/custom_speed.lua`
- `~/.local/share/vlc/lua/intf/custom_speed_intf.lua`

Then disable the interface in VLC: Tools → Preferences → All → Interface → Main interfaces

## License

GNU General Public License v2.0 or later

## Credits

- Author: Jay Groh
- Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>

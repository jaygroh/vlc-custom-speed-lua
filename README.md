# VLC Speed Scheduler

**Current Version: 2026.02.12.01**

A VLC media player Lua extension that calculates playback speed to finish a video in a specified time, with optional on-screen display of speed-adjusted remaining time.

## Features

### Speed Planner
- **Finish In**: Enter minutes, automatically calculates required playback speed
- **Finish By**: Select a clock time to see what speed is needed to finish by that time
- Speed results clamped to sensible 1x-4x range for audio quality
- One-click speed application with real-time duration calculation
- 5 or 1 minute interval options for clock time selection

### On-Screen Display (OSD)
- **Speed-adjusted remaining time**: Shows time remaining accounting for playback speed with inline speed indicator (e.g., "-25:00 (@ 1.5X)")
- **Estimated finish time**: Shows clock time when video will end (e.g., "Ends 3:45 PM")
- **Configurable layout**: Stack order control - choose which elements display in Top/Middle/Bottom positions
- **9 screen positions**: Place elements anywhere on screen (top-left, top, top-right, etc.)
- **12/24-hour clock**: Toggle between 12-hour (AM/PM) and 24-hour time format
- **Master toggle**: Enable/disable OSD display entirely

### Background Interface Script
- Optional background script that displays OSD overlays
- Must be enabled in Script Setup dialog
- Runs continuously while VLC is open

## Installation

The plugin consists of two files:
- `lua/extensions/custom_speed.lua` - Main extension with UI dialogs
- `lua/intf/custom_speed_intf.lua` - Background script for OSD display

### Copy Files to VLC Directory

Choose the paths for your operating system and copy both files:

**Linux:**
```
lua/extensions/custom_speed.lua → ~/.local/share/vlc/lua/extensions/
lua/intf/custom_speed_intf.lua → ~/.local/share/vlc/lua/intf/
```

**macOS:**
```
lua/extensions/custom_speed.lua → ~/Library/Application Support/org.videolan.vlc/lua/extensions/
lua/intf/custom_speed_intf.lua → ~/Library/Application Support/org.videolan.vlc/lua/intf/
```

**Windows:**
```
lua/extensions/custom_speed.lua → %APPDATA%\vlc\lua\extensions\
lua/intf/custom_speed_intf.lua → %APPDATA%\vlc\lua\intf\
```

**Restart VLC** after installation for changes to take effect.

## Usage

### First Time Setup

1. Open VLC and play a video
2. Go to **View** → **Speed Scheduler** → **Script Setup**
3. Check **"Enable interface script"** and click **Save**
4. **Restart VLC** for OSD script to activate

### Speed Planner

1. Play a video
2. Open **View** → **Speed Scheduler** → **Speed Planner**
3. **Finish In**: Enter hours/minutes, click **Apply**
4. **Finish By**: Select a time from the dropdown, click **Apply**
5. Speed adjusts automatically based on remaining video duration

### OSD Display Settings

1. Open **View** → **Speed Scheduler** → **OSD Display**
2. **Master Switch**: Check "Enable OSD" to display overlays
3. **Clock Format**: Toggle between 12-hour and 24-hour time
4. **Stack Order**: For each position (Top/Middle/Bottom):
   - Select which element to display (Remaining Time, Speed, Finish Time)
   - Check to enable/disable that element
   - Choose screen position (all 3 can use same position to stack vertically)
5. Click **Save & Close**

### Menu Structure

```
View → Speed Scheduler
    ├── Speed Planner       (Calculate speeds for finish times)
    ├── OSD Display         (Configure on-screen display)
    └── Script Setup        (Enable/disable background script)
```

## How It Works

The extension has two components:

1. **Extension** (`custom_speed.lua`): Main UI providing three dialogs:
   - Speed Planner: Calculate and apply speeds
   - OSD Display: Configure on-screen overlays
   - Script Setup: Enable the background interface script

2. **Interface Script** (`custom_speed_intf.lua`): Optional background script that:
   - Runs continuously while VLC is open
   - Displays OSD overlays based on current playback info
   - Must be explicitly enabled via Script Setup dialog
   - Can be disabled without uninstalling

Settings are persisted using VLC's config system (bookmark10 variable).

## Speed Limits

Speeds are limited to **1x - 4x**:
- **Below 1x**: Would slow down playback (not useful for finishing faster)
- **Above 4x**: Audio degradation becomes noticeable, playback becomes difficult to follow

## Compatibility

- VLC 2.1.0+ (requires Lua extension support)
- VLC 3.x+ recommended
- Linux, macOS, Windows

## Uninstall

Simply delete the two files from your VLC Lua directory:

```
~/.local/share/vlc/lua/extensions/custom_speed.lua
~/.local/share/vlc/lua/intf/custom_speed_intf.lua
```

Or if you only want to disable the background script without uninstalling:
1. Open **View** → **Speed Scheduler** → **Script Setup**
2. Uncheck **"Enable interface script"** and save
3. **Restart VLC**

## License

GNU General Public License v2.0 or later

## Credits

- Author: Jay Groh
- Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>

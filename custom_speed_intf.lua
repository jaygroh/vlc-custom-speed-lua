--[[
 Custom Speed Calculator - Interface Script for VLC

 Displays speed-adjusted remaining time and other info on screen.
 Runs in background, controlled by the extension settings.

 Copyright (C) 2026 Jay Groh

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>

 Installation:
   Place in: ~/.local/share/vlc/lua/intf/
   Enable via: Extension > Custom Speed Calculator > Interface Setup
--]]

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

config = {}  -- Global for loadstring
local cfg = {}

-- OSD channels - one per position to allow stacking
local OSD_CHANNELS = {
    ["top-left"] = 9876501,
    ["top"] = 9876502,
    ["top-right"] = 9876503,
    ["left"] = 9876504,
    ["center"] = 9876505,
    ["right"] = 9876506,
    ["bottom-left"] = 9876507,
    ["bottom"] = 9876508,
    ["bottom-right"] = 9876509
}

-- VLC version time correction (VLC 3+ uses microseconds)
local VLC_version = vlc.misc.version()
local TIME_DIVISOR = 1
if tonumber(string.sub(VLC_version, 1, 1)) >= 3 then
    TIME_DIVISOR = 1000000
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

function log(msg)
    vlc.msg.info("[custom_speed_intf] " .. msg)
end

function sleep(seconds)
    vlc.misc.mwait(vlc.misc.mdate() + seconds * 1000000)
end

function load_config()
    cfg = {}  -- Reset
    local s = vlc.config.get("bookmark10")
    if s and string.match(s, "^config={.*}$") then
        local ok, err = pcall(function()
            assert(loadstring(s))()
        end)
        if ok and config and config.CUSTOM_SPEED then
            cfg = config.CUSTOM_SPEED
        end
    end
    return cfg
end

--------------------------------------------------------------------------------
-- Time Formatting
--------------------------------------------------------------------------------

function format_time(seconds)
    if seconds <= 0 then return "--:--" end

    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%d:%02d", mins, secs)
    end
end

function format_clock_time(total_seconds, use_24h)
    -- Handle day overflow
    while total_seconds >= 86400 do
        total_seconds = total_seconds - 86400
    end
    while total_seconds < 0 do
        total_seconds = total_seconds + 86400
    end

    local hours = math.floor(total_seconds / 3600)
    local mins = math.floor((total_seconds % 3600) / 60)

    if use_24h then
        return string.format("%02d:%02d", hours, mins)
    else
        local period = "AM"
        local display_hour = hours

        if hours >= 12 then
            period = "PM"
            if hours > 12 then display_hour = hours - 12 end
        end
        if hours == 0 then display_hour = 12 end

        return string.format("%d:%02d %s", display_hour, mins, period)
    end
end

--------------------------------------------------------------------------------
-- OSD Display
--------------------------------------------------------------------------------

function get_playback_info()
    local input = vlc.object.input()
    if not input then return nil end

    local item = vlc.input.item()
    if not item then return nil end

    local duration = item:duration()
    if not duration or duration <= 0 then return nil end

    local elapsed_us = vlc.var.get(input, "time") or 0
    local elapsed = elapsed_us / TIME_DIVISOR
    local remaining = duration - elapsed
    local rate = vlc.var.get(input, "rate") or 1.0

    if remaining <= 0 then return nil end

    return {
        remaining = remaining,
        rate = rate
    }
end

function get_element_text(element_id, info, use_24h)
    if element_id == "remaining" then
        local adjusted = info.remaining / info.rate
        local prefix = ""
        if info.rate ~= 1.0 then
            prefix = "≈ "
        end
        return prefix .. format_time(adjusted) .. " remaining"

    elseif element_id == "speed" then
        -- Speed only shows when not 1x
        if info.rate ~= 1.0 then
            return string.format("%.2fx speed", info.rate)
        end
        return nil

    elseif element_id == "finish" then
        local now = os.date("*t")
        local now_seconds = now.hour * 3600 + now.min * 60 + now.sec
        local finish_seconds = now_seconds + (info.remaining / info.rate)
        return "Ends " .. format_clock_time(finish_seconds, use_24h)
    end

    return nil
end

function update_osd()
    load_config()

    -- Check if OSD is enabled
    if cfg.osd_enabled ~= true then
        return false
    end

    local info = get_playback_info()
    if not info then return false end

    -- Auto-hide logic: hide OSD after timeout of inactivity (works during playback)
    if cfg.autohide_enabled == true then
        local timeout = cfg.autohide_timeout or 5
        local now = vlc.misc.mdate() / 1000000
        local time_since_activity = now - (_osd_last_activity or now)

        if time_since_activity > timeout then
            -- Timeout reached, don't display OSD (but keep polling for activity)
            return false
        end
    end

    local use_24h = cfg.use_24h_clock == true

    -- Default slots if not configured
    local slots = cfg.osd_slots
    if not slots then
        slots = {
            top = { element = "remaining", show = true, position = "top-right" },
            middle = { element = "speed", show = true, position = "top-right" },
            bottom = { element = "finish", show = false, position = "top-right" }
        }
    end

    -- Process slots in order (top, middle, bottom)
    local slot_order = {"top", "middle", "bottom"}
    local by_position = {}

    for _, slot_name in ipairs(slot_order) do
        local slot = slots[slot_name]
        if slot and slot.show then
            local text = get_element_text(slot.element, info, use_24h)
            if text then
                local pos = slot.position or "top-right"
                if not by_position[pos] then by_position[pos] = {} end
                table.insert(by_position[pos], text)
            end
        end
    end

    -- Display stacked messages for each position
    local showed_any = false
    for pos, lines in pairs(by_position) do
        local combined = table.concat(lines, "\n")
        local channel = OSD_CHANNELS[pos] or 9876500
        vlc.osd.message(combined, channel, pos)
        showed_any = true
    end

    return showed_any
end

--------------------------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------------------------

function main_loop()
    log("Interface script starting (VLC " .. VLC_version .. ")")
    log("Time divisor: " .. TIME_DIVISOR)

    local current_uri = nil
    local loop_count = 0
    local last_speed = nil
    _osd_last_activity = vlc.misc.mdate() / 1000000

    while true do
        -- Check if VLC is closing
        if vlc.volume.get() == -256 then
            log("VLC closing, exiting interface")
            break
        end

        loop_count = loop_count + 1

        local status = vlc.playlist.status()

        if status == "stopped" then
            -- No input
            if current_uri then
                log("Playback stopped")
                current_uri = nil
                _osd_last_activity = vlc.misc.mdate() / 1000000
            end
            sleep(1)

        elseif status == "playing" or status == "paused" then
            local item = vlc.input.item()
            local uri = item and item:uri()

            if not uri then
                -- Transitioning
                sleep(0.1)
            elseif not current_uri or current_uri ~= uri then
                -- New input
                current_uri = uri
                _osd_last_activity = vlc.misc.mdate() / 1000000
                log("Now playing: " .. (item:name() or uri))

                -- Log config state on new playback
                load_config()
                log("OSD enabled: " .. tostring(cfg.osd_enabled))

                sleep(0.5)
            else
                -- Check if speed changed (user activity indicator)
                local input = vlc.object.input()
                local current_speed = input and vlc.var.get(input, "rate") or 1.0
                if last_speed and current_speed ~= last_speed then
                    _osd_last_activity = vlc.misc.mdate() / 1000000
                end
                last_speed = current_speed

                -- Current input - update OSD
                update_osd()

                if status == "paused" then
                    sleep(0.5)
                else
                    sleep(0.2)
                end
            end
        else
            sleep(1)
        end
    end
end

--------------------------------------------------------------------------------
-- Start
--------------------------------------------------------------------------------

os.setlocale("C", "all")
log("=== Custom Speed Interface Script Loaded ===")
main_loop()

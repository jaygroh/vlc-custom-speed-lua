--[[
 Speed Scheduler Extension for VLC

 Calculate playback speed to finish video in a specified time
 or by a specific clock time. Optional OSD display of speed-adjusted time.

 Copyright (C) 2026 Jay Groh

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
--]]

--------------------------------------------------------------------------------
-- Extension Descriptor
--------------------------------------------------------------------------------

function descriptor()
    return {
        title = "Speed Scheduler",
        version = "3.5.0",
        author = "Jay Groh",
        url = "https://github.com/jaygroh/vlc-custom-speed-lua",
        shortdesc = "Speed Scheduler",
        description = "Calculate playback speed to finish video in a specified time. " ..
                      "Optional on-screen display of speed-adjusted remaining time. " ..
                      "Quick speed presets included.",
        capabilities = {"menu"}
    }
end

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

function menu()
    return {
        "Speed Planner",
        "OSD Display",
        "Script Setup",
        "---",
        "Quick Speed: 0.25x",
        "Quick Speed: 0.5x",
        "Quick Speed: 0.75x",
        "Quick Speed: 1x",
        "Quick Speed: 1.25x",
        "Quick Speed: 1.5x",
        "Quick Speed: 1.75x",
        "Quick Speed: 2x",
        "Quick Speed: 3x",
        "Quick Speed: 4x"
    }
end

function trigger_menu(id)
    load_config()

    if id == 1 then
        show_planner_dialog()
    elseif id == 2 then
        show_osd_dialog()
    elseif id == 3 then
        show_setup_dialog()
    elseif id >= 5 and id <= 14 then
        -- Quick Speed items (IDs 5-14 map to quick_speeds indices 1-10)
        local speed_idx = id - 4
        if speed_idx >= 1 and speed_idx <= #quick_speeds then
            set_playback_rate(quick_speeds[speed_idx].speed)
        end
    end
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local MIN_SPEED = 1.0
local MAX_SPEED = 4.0
local INTF_SCRIPT = "custom_speed_intf"

local positions = {
    "top-left", "top", "top-right",
    "left", "center", "right",
    "bottom-left", "bottom", "bottom-right"
}

local position_labels = {
    ["top-left"] = "Top-Left",
    ["top"] = "Top",
    ["top-right"] = "Top-Right",
    ["left"] = "Left",
    ["center"] = "Center",
    ["right"] = "Right",
    ["bottom-left"] = "Bottom-Left",
    ["bottom"] = "Bottom",
    ["bottom-right"] = "Bottom-Right"
}

--------------------------------------------------------------------------------
-- Global State
--------------------------------------------------------------------------------

local dlg = nil
local cfg = {}
local widgets = {}
local time_increment = 5  -- 5 or 1 minutes

--------------------------------------------------------------------------------
-- Activation / Deactivation
--------------------------------------------------------------------------------

function activate()
    -- With menu capability, activate is called when extension is enabled
end

function deactivate()
    close_dialog()
end

function close()
    close_dialog()
end

function close_dialog()
    if dlg then
        dlg:delete()
        dlg = nil
    end
    widgets = {}
end

--------------------------------------------------------------------------------
-- Speed Planner Dialog
--------------------------------------------------------------------------------

function show_planner_dialog()
    close_dialog()

    dlg = vlc.dialog("Speed Planner")

    local item = vlc.input.item()

    if not item then
        dlg:add_label("No media is currently playing.", 1, 1, 4, 1)
        dlg:add_label("Play a video to use the planner.", 1, 2, 4, 1)
        dlg:add_label(" ", 1, 3, 4, 1)
        dlg:add_button("Close", close_dialog, 2, 4, 2, 1)
        dlg:show()
        return
    end

    local duration = item:duration()
    if not duration or duration <= 0 then
        dlg:add_label("Cannot determine video duration.", 1, 1, 4, 1)
        dlg:add_label("Try a different video file.", 1, 2, 4, 1)
        dlg:add_label(" ", 1, 3, 4, 1)
        dlg:add_button("Close", close_dialog, 2, 4, 2, 1)
        dlg:show()
        return
    end

    -- Row 1: Current video info
    local remaining = get_remaining_seconds()
    local rate = get_current_rate()
    widgets.info_label = dlg:add_label(
        "Remaining: " .. format_time(remaining) .. "  |  Speed: " .. format_speed(rate),
        1, 1, 3, 1)
    dlg:add_button("Refresh", refresh_planner, 4, 1, 1, 1)

    -- Row 2: Separator
    dlg:add_label(string.rep("-", 45), 1, 2, 4, 1)

    -- Row 3: FINISH IN header
    dlg:add_label("FINISH IN:", 1, 3, 4, 1)

    -- Row 4: Labels above dropdowns
    dlg:add_label("Hours", 1, 4, 2, 1)
    dlg:add_label("Minutes", 3, 4, 2, 1)

    -- Row 5: Dropdowns side by side
    widgets.hours_dropdown = dlg:add_dropdown(1, 5, 2, 1)
    widgets.mins_dropdown = dlg:add_dropdown(3, 5, 2, 1)

    -- Populate with valid times (1x-4x range)
    populate_finish_in_dropdowns()

    -- Row 6: Error message area (pre-sized to avoid resize)
    widgets.finish_in_error = dlg:add_label(string.rep(" ", 25), 1, 6, 4, 1)

    -- Row 7: Apply button centered
    dlg:add_button("Apply", apply_finish_in_speed, 2, 7, 2, 1)

    -- Row 8: Separator
    dlg:add_label(string.rep("-", 45), 1, 8, 4, 1)

    -- Row 9: FINISH BY header
    dlg:add_label("FINISH BY:", 1, 9, 4, 1)

    -- Row 10: Time interval buttons
    dlg:add_label("Interval:", 1, 10, 1, 1)
    local btn5_text = time_increment == 5 and "[ 5 min ]" or "  5 min  "
    local btn1_text = time_increment == 1 and "[ 1 min ]" or "  1 min  "
    dlg:add_button(btn5_text, set_increment_5, 2, 10, 1, 1)
    dlg:add_button(btn1_text, set_increment_1, 3, 10, 1, 1)

    -- Row 11: Finish By controls
    dlg:add_label("Time:", 1, 11, 1, 1)
    widgets.time_dropdown = dlg:add_dropdown(2, 11, 2, 1)
    dlg:add_button("Apply", apply_finish_by_speed, 4, 11, 1, 1)

    populate_time_dropdown()

    -- Row 12: Close button
    dlg:add_button("Close", close_dialog, 2, 12, 2, 1)

    dlg:show()
end

function set_increment_5()
    time_increment = 5
    show_planner_dialog()
end

function set_increment_1()
    time_increment = 1
    show_planner_dialog()
end

function refresh_planner()
    show_planner_dialog()
end

function populate_finish_in_dropdowns()
    -- Populate hours dropdown (0-10)
    for h = 0, 10 do
        widgets.hours_dropdown:add_value(tostring(h), h + 1)
    end

    -- Populate minutes dropdown (0-55 in 5-min increments)
    for m = 0, 55, 5 do
        widgets.mins_dropdown:add_value(string.format("%02d", m), (m / 5) + 1)
    end
end

function do_calculate_finish_in()
    if not widgets.hours_dropdown or not widgets.mins_dropdown then return nil, nil end

    local h_idx = widgets.hours_dropdown:get_value()
    local m_idx = widgets.mins_dropdown:get_value()

    if not h_idx or h_idx == 0 or not m_idx or m_idx == 0 then
        return nil, "Select hours and minutes"
    end

    -- Convert indices to actual values
    local hours = h_idx - 1  -- 0-10
    local minutes = (m_idx - 1) * 5  -- 0, 5, 10, ... 55

    local total_minutes = hours * 60 + minutes
    if total_minutes < 1 then
        return nil, "Select time > 0"
    end

    local remaining = get_remaining_seconds()
    if remaining <= 0 then
        return nil, "No video playing"
    end

    local speed = remaining / (total_minutes * 60)

    if speed > MAX_SPEED then
        return nil, "Exceeds 4x speed!"
    elseif speed < MIN_SPEED then
        return nil, "Below 1x speed!"
    else
        return speed, nil
    end
end

function apply_finish_in_speed()
    local speed, error_msg = do_calculate_finish_in()
    if speed then
        set_playback_rate(speed)
        show_planner_dialog()
    elseif error_msg and widgets.finish_in_error then
        widgets.finish_in_error:set_text("* " .. error_msg)
    end
end

function apply_finish_by_speed()
    if not widgets.time_dropdown then return end

    local idx = widgets.time_dropdown:get_value()
    if idx and idx > 0 and widgets.time_entries and widgets.time_entries[idx] then
        local speed = widgets.time_entries[idx].speed
        set_playback_rate(speed)
    end
    -- Refresh to update display and avoid resize
    show_planner_dialog()
end

function populate_time_dropdown()
    widgets.time_entries = {}

    local remaining = get_remaining_seconds()
    if remaining <= 0 then
        widgets.time_dropdown:add_value("No video playing", 0)
        return
    end

    local now = os.date("*t")
    local now_secs = now.hour * 3600 + now.min * 60 + now.sec

    -- Round to next increment
    local mins_to_add = time_increment - (now.min % time_increment)
    if mins_to_add == 0 then mins_to_add = time_increment end

    local start_min = now.min + mins_to_add
    local start_hour = now.hour
    if start_min >= 60 then
        start_min = start_min - 60
        start_hour = (start_hour + 1) % 24
    end

    -- More entries for 1-minute increments
    local max_entries = time_increment == 1 and 120 or 48

    local count = 0
    for i = 0, max_entries do
        local t_min = start_min + (i * time_increment)
        local t_hour = start_hour
        while t_min >= 60 do
            t_min = t_min - 60
            t_hour = (t_hour + 1) % 24
        end

        local t_secs = t_hour * 3600 + t_min * 60
        local secs_until = t_secs - now_secs
        if secs_until <= 0 then secs_until = secs_until + 86400 end

        local speed = remaining / secs_until
        if speed >= MIN_SPEED and speed <= MAX_SPEED then
            count = count + 1
            local use_24h = cfg.use_24h_clock == true
            table.insert(widgets.time_entries, {
                time = format_clock_time(t_hour, t_min, use_24h),
                speed = speed
            })
            widgets.time_dropdown:add_value(
                format_clock_time(t_hour, t_min, use_24h) .. " = " .. format_speed(speed),
                count
            )
        end
    end

    if count == 0 then
        widgets.time_dropdown:add_value("No times in 1x-4x range", 0)
    end
end

--------------------------------------------------------------------------------
-- Quick Speed Presets
--------------------------------------------------------------------------------

local quick_speeds = {
    { label = "0.25x", speed = 0.25 },
    { label = "0.5x", speed = 0.5 },
    { label = "0.75x", speed = 0.75 },
    { label = "1x", speed = 1.0 },
    { label = "1.25x", speed = 1.25 },
    { label = "1.5x", speed = 1.5 },
    { label = "1.75x", speed = 1.75 },
    { label = "2x", speed = 2.0 },
    { label = "3x", speed = 3.0 },
    { label = "4x", speed = 4.0 }
}

--------------------------------------------------------------------------------
-- OSD Display Dialog
--------------------------------------------------------------------------------

-- Element options for dropdowns
local element_options = {
    { id = "remaining", label = "Remaining Time" },
    { id = "speed", label = "Current Speed" },
    { id = "finish", label = "Finish Time" }
}

function show_osd_dialog()
    close_dialog()
    load_config()

    -- Set defaults for new slot-based config
    if not cfg.osd_slots then
        cfg.osd_slots = {
            top = { element = "remaining", show = true, position = "top-right" },
            middle = { element = "speed", show = true, position = "top-right" },
            bottom = { element = "finish", show = false, position = "top-right" }
        }
    end

    dlg = vlc.dialog("OSD Display")

    -- Row 1: Master enable
    dlg:add_label("Master Switch:", 1, 1, 2, 1)
    widgets.osd_enabled = dlg:add_check_box("Enable OSD", cfg.osd_enabled == true, 3, 1, 3, 1)

    -- Row 2: Clock format
    dlg:add_label("Clock Format:", 1, 2, 2, 1)
    widgets.use_24h = dlg:add_check_box("24-hour", cfg.use_24h_clock == true, 3, 2, 3, 1)

    -- Row 3: Auto-hide mode
    dlg:add_label("Auto-Hide:", 1, 3, 2, 1)
    widgets.autohide_enabled = dlg:add_check_box("Enable", cfg.autohide_enabled == true, 3, 3, 1, 1)
    dlg:add_label("Timeout (sec):", 4, 3, 1, 1)
    widgets.autohide_timeout = dlg:add_text_input(tostring(cfg.autohide_timeout or 5), 5, 3, 2, 1)

    -- Row 4: Separator
    dlg:add_label(string.rep("-", 50), 1, 4, 6, 1)

    -- Row 5: Description
    dlg:add_label("Stack order (when elements share same position):", 1, 5, 6, 1)

    -- Row 6: Column headers
    dlg:add_label("Slot", 1, 6, 1, 1)
    dlg:add_label("Element", 2, 6, 2, 1)
    dlg:add_label("Show", 4, 6, 1, 1)
    dlg:add_label("Position", 5, 6, 2, 1)

    -- Row 7: Top slot
    dlg:add_label("Top:", 1, 7, 1, 1)
    widgets.slot_top_elem = dlg:add_dropdown(2, 7, 2, 1)
    populate_element_dropdown(widgets.slot_top_elem, cfg.osd_slots.top.element)
    widgets.slot_top_show = dlg:add_check_box("", cfg.osd_slots.top.show == true, 4, 7, 1, 1)
    widgets.slot_top_pos = dlg:add_dropdown(5, 7, 2, 1)
    populate_position_dropdown(widgets.slot_top_pos, cfg.osd_slots.top.position)

    -- Row 8: Middle slot
    dlg:add_label("Middle:", 1, 8, 1, 1)
    widgets.slot_mid_elem = dlg:add_dropdown(2, 8, 2, 1)
    populate_element_dropdown(widgets.slot_mid_elem, cfg.osd_slots.middle.element)
    widgets.slot_mid_show = dlg:add_check_box("", cfg.osd_slots.middle.show == true, 4, 8, 1, 1)
    widgets.slot_mid_pos = dlg:add_dropdown(5, 8, 2, 1)
    populate_position_dropdown(widgets.slot_mid_pos, cfg.osd_slots.middle.position)

    -- Row 9: Bottom slot
    dlg:add_label("Bottom:", 1, 9, 1, 1)
    widgets.slot_bot_elem = dlg:add_dropdown(2, 9, 2, 1)
    populate_element_dropdown(widgets.slot_bot_elem, cfg.osd_slots.bottom.element)
    widgets.slot_bot_show = dlg:add_check_box("", cfg.osd_slots.bottom.show == true, 4, 9, 1, 1)
    widgets.slot_bot_pos = dlg:add_dropdown(5, 9, 2, 1)
    populate_position_dropdown(widgets.slot_bot_pos, cfg.osd_slots.bottom.position)

    -- Row 10: Note about speed
    dlg:add_label("Note: Speed only shows when not at 1x", 1, 10, 6, 1)

    -- Row 11: Note about script
    dlg:add_label("* Enable script in Script Setup for OSD", 1, 11, 6, 1)

    -- Row 12: Status (pre-sized to prevent window resize)
    widgets.status = dlg:add_label(string.rep(" ", 35), 1, 12, 6, 1)

    -- Row 13: Buttons
    dlg:add_button("Apply", apply_osd_settings, 1, 13, 2, 1)
    dlg:add_button("Save & Close", save_osd_and_close, 3, 13, 2, 1)
    dlg:add_button("Cancel", close_dialog, 5, 13, 2, 1)

    dlg:show()
end

function populate_element_dropdown(dropdown, saved_element)
    local current = saved_element or "remaining"

    -- Find current element's label
    local current_label = "Remaining Time"
    for _, opt in ipairs(element_options) do
        if opt.id == current then
            current_label = opt.label
            break
        end
    end

    -- Add current element first (so it's selected by default)
    dropdown:add_value(current_label, 1)

    -- Add other elements
    local idx = 2
    for _, opt in ipairs(element_options) do
        if opt.id ~= current then
            dropdown:add_value(opt.label, idx)
            idx = idx + 1
        end
    end

    -- Store mapping for this dropdown
    if not widgets.elem_maps then widgets.elem_maps = {} end
    local map = {current}
    for _, opt in ipairs(element_options) do
        if opt.id ~= current then
            table.insert(map, opt.id)
        end
    end
    widgets.elem_maps[dropdown] = map
end

function get_selected_element(dropdown)
    local idx = dropdown:get_value()
    local map = widgets.elem_maps and widgets.elem_maps[dropdown]
    if map and idx >= 1 and idx <= #map then
        return map[idx]
    end
    return "remaining"
end

function populate_position_dropdown(dropdown, saved_position)
    -- Default to top-right if no saved position
    local current = saved_position or "top-right"

    -- Add the saved/current position first (so it's selected by default)
    local current_label = position_labels[current] or "Top-Right"
    dropdown:add_value(current_label, 1)

    -- Add all other positions
    local idx = 2
    for _, pos in ipairs(positions) do
        if pos ~= current then
            dropdown:add_value(position_labels[pos], idx)
            idx = idx + 1
        end
    end

    -- Store mapping for this dropdown
    if not widgets.pos_maps then widgets.pos_maps = {} end
    local map = {current}
    for _, pos in ipairs(positions) do
        if pos ~= current then
            table.insert(map, pos)
        end
    end
    widgets.pos_maps[dropdown] = map
end

function get_selected_position(dropdown)
    local idx = dropdown:get_value()
    local map = widgets.pos_maps and widgets.pos_maps[dropdown]
    if map and idx >= 1 and idx <= #map then
        return map[idx]
    end
    return "top-right"
end

function apply_osd_settings()
    cfg.osd_enabled = widgets.osd_enabled:get_checked()
    cfg.use_24h_clock = widgets.use_24h:get_checked()
    cfg.autohide_enabled = widgets.autohide_enabled:get_checked()

    -- Validate and parse timeout
    local timeout_str = widgets.autohide_timeout:get_text()
    local timeout = tonumber(timeout_str) or 5
    if timeout < 1 then timeout = 1 end
    if timeout > 300 then timeout = 300 end  -- Max 5 minutes
    cfg.autohide_timeout = timeout

    -- Slot-based settings
    cfg.osd_slots = {
        top = {
            element = get_selected_element(widgets.slot_top_elem),
            show = widgets.slot_top_show:get_checked(),
            position = get_selected_position(widgets.slot_top_pos)
        },
        middle = {
            element = get_selected_element(widgets.slot_mid_elem),
            show = widgets.slot_mid_show:get_checked(),
            position = get_selected_position(widgets.slot_mid_pos)
        },
        bottom = {
            element = get_selected_element(widgets.slot_bot_elem),
            show = widgets.slot_bot_show:get_checked(),
            position = get_selected_position(widgets.slot_bot_pos)
        }
    }

    save_config()
    -- Refresh dialog to show saved positions and avoid resize
    show_osd_dialog()
end

function save_osd_and_close()
    apply_osd_settings()
    close_dialog()
end

--------------------------------------------------------------------------------
-- Script Setup Dialog
--------------------------------------------------------------------------------

function show_setup_dialog()
    close_dialog()

    local _, lua_intf, _, ti = get_vlc_intf_settings()
    local is_enabled = ti and lua_intf == INTF_SCRIPT

    dlg = vlc.dialog("Script Setup")

    -- Row 1: Title
    dlg:add_label("Background Interface Script", 1, 1, 4, 1)

    -- Row 2: Separator
    dlg:add_label(string.rep("-", 45), 1, 2, 4, 1)

    -- Row 3-4: Explanation
    dlg:add_label("The interface script runs in the background", 1, 3, 4, 1)
    dlg:add_label("to display OSD overlays while you watch.", 1, 4, 4, 1)

    -- Row 5: Spacer
    dlg:add_label(" ", 1, 5, 4, 1)

    -- Row 6: Status
    local status_text = is_enabled and "Current Status: ENABLED" or "Current Status: DISABLED"
    dlg:add_label(status_text, 1, 6, 4, 1)

    -- Row 7: Enable checkbox
    widgets.intf_enabled = dlg:add_check_box("Enable interface script", is_enabled, 1, 7, 4, 1)

    -- Row 8: Warning
    dlg:add_label("* Restart VLC after changing this setting", 1, 8, 4, 1)

    -- Row 9: Status message (pre-sized to prevent resize)
    widgets.status = dlg:add_label(string.rep(" ", 30), 1, 9, 4, 1)

    -- Row 10: Buttons
    dlg:add_button("Save & Close", save_setup_and_close, 1, 10, 2, 1)
    dlg:add_button("Cancel", close_dialog, 3, 10, 2, 1)

    dlg:show()
end

function save_intf_settings()
    local enable = widgets.intf_enabled:get_checked()
    local _, _, t, ti = get_vlc_intf_settings()

    if enable then
        if not ti then table.insert(t, "luaintf") end
        vlc.config.set("lua-intf", INTF_SCRIPT)
    else
        if ti then table.remove(t, ti) end
    end
    vlc.config.set("extraintf", table.concat(t, ":"))

    save_config()
    widgets.status:set_text("Saved! Restart VLC to apply.")
end

function save_setup_and_close()
    save_intf_settings()
    close_dialog()
end

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

function get_remaining_seconds()
    local input = vlc.object.input()
    if not input then return 0 end

    local item = vlc.input.item()
    if not item then return 0 end

    local duration = item:duration()
    if not duration or duration <= 0 then return 0 end

    local current_us = vlc.var.get(input, "time") or 0
    local current = current_us / 1000000

    local remaining = duration - current
    return remaining > 0 and remaining or 0
end

function get_current_rate()
    local input = vlc.object.input()
    if not input then return 1.0 end
    return vlc.var.get(input, "rate") or 1.0
end

function set_playback_rate(speed)
    local input = vlc.object.input()
    if not input then return false end
    if speed < MIN_SPEED or speed > MAX_SPEED then return false end
    vlc.var.set(input, "rate", speed)
    return true
end

function format_time(seconds)
    if seconds <= 0 then return "--:--" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

function format_speed(speed)
    return string.format("%.2fx", speed)
end

function format_clock_time(hour, minute, use_24h)
    if use_24h then
        return string.format("%02d:%02d", hour, minute)
    else
        local period = "AM"
        local h = hour
        if hour >= 12 then
            period = "PM"
            if hour > 12 then h = hour - 12 end
        end
        if hour == 0 then h = 12 end
        return string.format("%d:%02d %s", h, minute, period)
    end
end

--------------------------------------------------------------------------------
-- Config Management
--------------------------------------------------------------------------------

function load_config()
    cfg = {}
    local s = vlc.config.get("bookmark10")
    if s and string.match(s, "^config={.*}$") then
        pcall(function()
            assert(loadstring(s))()
            if config and config.CUSTOM_SPEED then
                cfg = config.CUSTOM_SPEED
            end
        end)
    end
end

function save_config()
    local s = vlc.config.get("bookmark10")
    local full = {}
    if s and string.match(s, "^config={.*}$") then
        pcall(function()
            assert(loadstring(s))()
            full = config or {}
        end)
    end
    full.CUSTOM_SPEED = cfg
    vlc.config.set("bookmark10", "config=" .. serialize(full))
end

function serialize(t)
    if type(t) == "table" then
        local s = '{'
        for k, v in pairs(t) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. ']=' .. serialize(v) .. ','
        end
        return s .. '}'
    elseif type(t) == "string" then
        return string.format("%q", t)
    else
        return tostring(t)
    end
end

function get_vlc_intf_settings()
    local extraintf = vlc.config.get("extraintf") or ""
    local lua_intf = vlc.config.get("lua-intf") or ""
    local t = {}
    local ti = nil

    for v in string.gmatch(extraintf, "[^:]+") do
        table.insert(t, v)
        if v == "luaintf" then ti = #t end
    end

    return extraintf, lua_intf, t, ti
end

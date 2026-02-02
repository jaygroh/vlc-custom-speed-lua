--[[
 Custom Speed Calculator Extension for VLC

 Calculate playback speed to finish video in a specified time
 or by a specific clock time.

 Copyright (C) 2026 Jay Groh

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
--]]

-- Extension descriptor
function descriptor()
    return {
        title = "Custom Speed Calculator",
        version = "1.1.0",
        author = "Jay Groh",
        url = "https://github.com/jaygroh/vlc-custom-speed-lua",
        shortdesc = "Custom Speed Calculator",
        description = "Calculate playback speed to finish video in a specified time or by a specific clock time.",
        capabilities = {"menu"}
    }
end

-- Configuration
local MIN_SPEED = 1.0
local MAX_SPEED = 4.0

-- Global variables
local dlg = nil
local current_tab = "finish_in"

-- UI widgets (persistent)
local w_remaining_label = nil
local w_current_speed_label = nil
local w_tab_finish_in = nil
local w_tab_finish_by = nil
local w_status_label = nil

-- Tab-specific widgets (cleared on tab switch)
local tab_widgets = {}

-- State
local time_entries = {}

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

function menu()
    return {"Open Custom Speed Calculator"}
end

function trigger_menu(id)
    if id == 1 then
        show_dialog()
    end
end

--------------------------------------------------------------------------------
-- Activation/Deactivation
--------------------------------------------------------------------------------

function activate()
end

function deactivate()
    if dlg then
        dlg:delete()
        dlg = nil
    end
end

--------------------------------------------------------------------------------
-- Dialog Management
--------------------------------------------------------------------------------

function show_dialog()
    if dlg then
        dlg:delete()
        dlg = nil
    end
    tab_widgets = {}

    -- Check if input is available
    local item = vlc.input.item()
    if not item then
        dlg = vlc.dialog("Custom Speed Calculator")
        dlg:add_label("No media is currently playing.", 1, 1, 2, 1)
        dlg:add_label("Please play a video first.", 1, 2, 2, 1)
        dlg:add_button("Close", on_close, 1, 3, 2, 1)
        dlg:show()
        return
    end

    local duration = item:duration()
    if not duration or duration <= 0 then
        dlg = vlc.dialog("Custom Speed Calculator")
        dlg:add_label("Cannot determine video duration.", 1, 1, 2, 1)
        dlg:add_label("This may be a live stream.", 1, 2, 2, 1)
        dlg:add_button("Close", on_close, 1, 3, 2, 1)
        dlg:show()
        return
    end

    dlg = vlc.dialog("Custom Speed Calculator")

    -- Row 1: Header info
    w_remaining_label = dlg:add_label("Remaining: --:--", 1, 1, 1, 1)
    w_current_speed_label = dlg:add_label("Speed: 1.00x", 2, 1, 1, 1)

    -- Row 2: Tab buttons
    w_tab_finish_in = dlg:add_button("[ Finish In ]", switch_to_finish_in, 1, 2, 1, 1)
    w_tab_finish_by = dlg:add_button("  Finish By  ", switch_to_finish_by, 2, 2, 1, 1)

    -- Row 3+: Content area (populated by tab functions)
    -- Row 7: Status
    w_status_label = dlg:add_label(" ", 1, 7, 2, 1)

    -- Row 8: Close button (always visible)
    dlg:add_button("Close", on_close, 1, 8, 2, 1)

    -- Initialize with Finish In tab
    current_tab = "finish_in"
    update_header()
    show_finish_in_content()

    dlg:show()
end

--------------------------------------------------------------------------------
-- Tab Content Management
--------------------------------------------------------------------------------

function clear_tab_content()
    for _, widget in ipairs(tab_widgets) do
        if widget then
            dlg:del_widget(widget)
        end
    end
    tab_widgets = {}
end

function show_finish_in_content()
    clear_tab_content()

    -- Row 3: Label
    local lbl = dlg:add_label("Finish remaining video in:", 1, 3, 2, 1)
    table.insert(tab_widgets, lbl)

    -- Row 4: Input and suffix
    local input = dlg:add_text_input("30", 1, 4, 1, 1)
    table.insert(tab_widgets, input)
    tab_widgets.minutes_input = input

    local suffix = dlg:add_label("minutes", 2, 4, 1, 1)
    table.insert(tab_widgets, suffix)

    -- Row 5: Calculated speed (large)
    local calc = dlg:add_label("--", 1, 5, 2, 1)
    table.insert(tab_widgets, calc)
    tab_widgets.calculated_label = calc

    -- Row 6: Apply button
    local btn = dlg:add_button("Apply Speed", on_apply_finish_in, 1, 6, 2, 1)
    table.insert(tab_widgets, btn)

    -- Calculate initial value
    update_finish_in_calculation()
end

function show_finish_by_content()
    clear_tab_content()
    populate_time_entries()

    -- Row 3: Label
    local lbl = dlg:add_label("Select a time to finish by:", 1, 3, 2, 1)
    table.insert(tab_widgets, lbl)

    -- Row 4: Dropdown
    local dropdown = dlg:add_dropdown(1, 4, 2, 1)
    table.insert(tab_widgets, dropdown)
    tab_widgets.time_dropdown = dropdown

    -- Populate dropdown
    if #time_entries == 0 then
        dropdown:add_value("No valid times available", 0)
    else
        for i, entry in ipairs(time_entries) do
            local display = entry.time .. "  →  " .. format_speed(entry.speed)
            dropdown:add_value(display, i)
        end
    end

    -- Row 5: Selected speed info
    local info = dlg:add_label("Select a time above", 1, 5, 2, 1)
    table.insert(tab_widgets, info)
    tab_widgets.info_label = info

    -- Row 6: Apply button
    local btn = dlg:add_button("Apply Speed", on_apply_finish_by, 1, 6, 2, 1)
    table.insert(tab_widgets, btn)
end

--------------------------------------------------------------------------------
-- Tab Switching
--------------------------------------------------------------------------------

function switch_to_finish_in()
    if current_tab == "finish_in" then return end
    current_tab = "finish_in"

    w_tab_finish_in:set_text("[ Finish In ]")
    w_tab_finish_by:set_text("  Finish By  ")
    w_status_label:set_text(" ")

    update_header()
    show_finish_in_content()
end

function switch_to_finish_by()
    if current_tab == "finish_by" then return end
    current_tab = "finish_by"

    w_tab_finish_in:set_text("  Finish In  ")
    w_tab_finish_by:set_text("[ Finish By ]")
    w_status_label:set_text(" ")

    update_header()
    show_finish_by_content()
end

--------------------------------------------------------------------------------
-- Time/Speed Calculations
--------------------------------------------------------------------------------

function get_remaining_seconds()
    local input = vlc.object.input()
    if not input then return 0 end

    local item = vlc.input.item()
    if not item then return 0 end

    local duration = item:duration()
    if not duration or duration <= 0 then return 0 end

    local current_time_us = vlc.var.get(input, "time")
    if not current_time_us then current_time_us = 0 end
    local current_time = current_time_us / 1000000

    local remaining = duration - current_time
    return remaining > 0 and remaining or 0
end

function get_current_rate()
    local input = vlc.object.input()
    if not input then return 1.0 end
    local rate = vlc.var.get(input, "rate")
    return rate or 1.0
end

function set_playback_rate(speed)
    local input = vlc.object.input()
    if not input then return false end
    if speed < MIN_SPEED or speed > MAX_SPEED then return false end
    vlc.var.set(input, "rate", speed)
    return true
end

function calculate_speed(target_seconds)
    local remaining = get_remaining_seconds()
    if remaining <= 0 or target_seconds <= 0 then return 0 end
    local speed = remaining / target_seconds
    if speed < MIN_SPEED or speed > MAX_SPEED then return 0 end
    return speed
end

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

function format_speed(speed)
    return string.format("%.2fx", speed)
end

function format_clock_time(hour, minute)
    local period = "AM"
    local display_hour = hour
    if hour >= 12 then
        period = "PM"
        if hour > 12 then display_hour = hour - 12 end
    end
    if hour == 0 then display_hour = 12 end
    return string.format("%d:%02d %s", display_hour, minute, period)
end

--------------------------------------------------------------------------------
-- UI Updates
--------------------------------------------------------------------------------

function update_header()
    if not dlg then return end
    local remaining = get_remaining_seconds()
    local rate = get_current_rate()

    if w_remaining_label then
        w_remaining_label:set_text("Remaining: " .. format_time(remaining))
    end
    if w_current_speed_label then
        w_current_speed_label:set_text("Speed: " .. format_speed(rate))
    end
end

function update_finish_in_calculation()
    if not tab_widgets.minutes_input or not tab_widgets.calculated_label then return end

    local minutes_text = tab_widgets.minutes_input:get_text()
    local minutes = tonumber(minutes_text)

    if not minutes or minutes < 1 or minutes > 600 then
        tab_widgets.calculated_label:set_text("Enter 1-600 minutes")
        return
    end

    local target_seconds = minutes * 60
    local speed = calculate_speed(target_seconds)

    if speed > 0 then
        tab_widgets.calculated_label:set_text("Speed needed: " .. format_speed(speed))
    else
        local remaining = get_remaining_seconds()
        if remaining <= 0 then
            tab_widgets.calculated_label:set_text("No video playing")
        else
            local required = remaining / target_seconds
            if required < MIN_SPEED then
                tab_widgets.calculated_label:set_text("Would be below 1x (video too short)")
            elseif required > MAX_SPEED then
                tab_widgets.calculated_label:set_text("Would exceed 4x (need more time)")
            end
        end
    end
end

function populate_time_entries()
    time_entries = {}

    local remaining = get_remaining_seconds()
    if remaining <= 0 then return end

    local now = os.date("*t")
    local current_hour = now.hour
    local current_min = now.min

    -- Round up to next 5-minute increment
    local minutes_to_add = 5 - (current_min % 5)
    if minutes_to_add == 0 then minutes_to_add = 5 end

    local start_min = current_min + minutes_to_add
    local start_hour = current_hour

    if start_min >= 60 then
        start_min = start_min - 60
        start_hour = start_hour + 1
        if start_hour >= 24 then start_hour = start_hour - 24 end
    end

    local now_total_seconds = current_hour * 3600 + current_min * 60 + now.sec

    -- Add entries for next 4 hours in 5-minute increments
    for i = 0, 47 do
        local target_min = start_min + (i * 5)
        local target_hour = start_hour

        while target_min >= 60 do
            target_min = target_min - 60
            target_hour = target_hour + 1
        end
        if target_hour >= 24 then target_hour = target_hour - 24 end

        local target_total_seconds = target_hour * 3600 + target_min * 60
        local seconds_until = target_total_seconds - now_total_seconds
        if seconds_until <= 0 then seconds_until = seconds_until + (24 * 3600) end

        local speed = remaining / seconds_until

        if speed >= MIN_SPEED and speed <= MAX_SPEED then
            table.insert(time_entries, {
                time = format_clock_time(target_hour, target_min),
                speed = speed,
                seconds_until = seconds_until
            })
        end
    end
end

--------------------------------------------------------------------------------
-- Button Handlers
--------------------------------------------------------------------------------

function on_apply_finish_in()
    if not tab_widgets.minutes_input then return end

    update_header()
    update_finish_in_calculation()

    local minutes_text = tab_widgets.minutes_input:get_text()
    local minutes = tonumber(minutes_text)

    if not minutes or minutes < 1 or minutes > 600 then
        w_status_label:set_text("Invalid minutes (1-600)")
        return
    end

    local target_seconds = minutes * 60
    local speed = calculate_speed(target_seconds)

    if speed > 0 then
        if set_playback_rate(speed) then
            w_status_label:set_text("Speed set to " .. format_speed(speed))
            update_header()
        else
            w_status_label:set_text("Failed to set speed")
        end
    else
        w_status_label:set_text("Cannot apply - speed out of range")
    end
end

function on_apply_finish_by()
    if not tab_widgets.time_dropdown then return end

    local selection = tab_widgets.time_dropdown:get_value()

    if not selection or selection == 0 or not time_entries[selection] then
        w_status_label:set_text("Please select a time first")
        return
    end

    local speed = time_entries[selection].speed

    if set_playback_rate(speed) then
        w_status_label:set_text("Speed set to " .. format_speed(speed))
        update_header()
    else
        w_status_label:set_text("Failed to set speed")
    end
end

function on_close()
    if dlg then
        dlg:delete()
        dlg = nil
    end
end

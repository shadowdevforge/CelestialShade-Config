#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: UNIFIED SCREENSHOT CONTROLLER
-- -----------------------------------------------------

local home = os.getenv("HOME")
local rofi_conf = home .. "/.config/hypr/config/rofi/config.rasi"
local save_dir = home .. "/Pictures/Screenshots"

-- Ensure screenshot dir exists
os.execute("mkdir -p " .. save_dir)

-- :: HELPER FUNCTIONS ::

local function rofi_menu(prompt, options)
    local list = ""
    for _, item in ipairs(options) do
        list = list .. item.label .. "\n"
    end
    
    local cmd = string.format("echo -e '%s' | rofi -dmenu -theme %s -p '%s'", list, rofi_conf, prompt)
    local handle = io.popen(cmd)
    local selection = handle:read("*a"):gsub("\n", "")
    handle:close()
    
    for _, item in ipairs(options) do
        if item.label == selection then
            return item.id
        end
    end
    return nil
end

local function notify(msg)
    os.execute("notify-send -u low -a 'Celestial Shot' '" .. msg .. "'")
end

-- :: LOGIC ::

-- 1. Select Mode (If not passed as arg)
local mode = arg[1]

if not mode then
    mode = rofi_menu("    Mode", {
        { label = "     Region",  id = "region" },
        { label = "     Window",  id = "window" },
        { label = "     Monitor", id = "output" }
    })
end

if not mode then return end -- User cancelled

-- 2. Select Action
local action = rofi_menu("    Action", {
    { label = "     Save",             id = "save" },
    { label = "     Copy",             id = "copy" },
    { label = "     Save + Copy",      id = "both" }
})

if not action then return end -- User cancelled

-- 3. Execute
-- We use a timestamp for filename to allow 'Both' to work cleanly
local timestamp = os.date("%Y-%m-%d-%H%M%S.png")
local filepath = save_dir .. "/" .. timestamp

if action == "copy" then
    -- Copy Only
    os.execute("hyprshot -m " .. mode .. " --clipboard-only")
    notify("Copied to clipboard")

elseif action == "save" then
    -- Save Only
    os.execute("hyprshot -m " .. mode .. " -o " .. save_dir .. " -f " .. timestamp)
    notify("Saved to " .. filepath)

elseif action == "both" then
    -- Save AND Copy
    -- Hyprshot freezes -> Saves to file -> We cat file to wl-copy
    local cmd = string.format("hyprshot -m %s -o %s -f %s", mode, save_dir, timestamp)
    os.execute(cmd)
    
    -- Now copy the file blob to clipboard
    os.execute("cat " .. filepath .. " | wl-copy")
    notify("Saved & Copied to clipboard")
end

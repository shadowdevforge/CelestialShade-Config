#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: CLIPBOARD MANAGER
-- -----------------------------------------------------

local home = os.getenv("HOME")
local rofi_conf = home .. "/.config/hypr/config/rofi/config.rasi"

-- 1. Dependencies Check (Simple binary check)
local function has_bin(bin)
    return os.execute("command -v " .. bin .. " > /dev/null 2>&1")
end

if not has_bin("cliphist") or not has_bin("wl-copy") then
    os.execute("notify-send -u critical 'Clipboard Error' 'Missing dependencies: cliphist or wl-clipboard'")
    return
end

-- 2. Launch Rofi with Cliphist data
local cmd = string.format("cliphist list | rofi -dmenu -theme %s -p '  Clipboard'", rofi_conf)
local handle = io.popen(cmd)
local selection = handle:read("*a")
handle:close()

-- 3. Process Selection
if selection and selection ~= "" then
    -- Escape single quotes for shell safety
    local safe_selection = selection:gsub("'", "'\\''")
    local decode_cmd = string.format("echo '%s' | cliphist decode | wl-copy", safe_selection)
    
    os.execute(decode_cmd)
    os.execute("notify-send -u low 'Celestial Shade' 'Copied to clipboard'")
end

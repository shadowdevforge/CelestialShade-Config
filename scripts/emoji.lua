#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: EMOJI PICKER (Corrected)
-- -----------------------------------------------------

local home = os.getenv("HOME")
local rofi_conf = home .. "/.config/hypr/config/rofi/config.rasi"
local asset_dir = home .. "/.config/hypr/assets"
local cache_file = asset_dir .. "/emojis.txt"
-- The URL you provided which groups emojis
local json_url = "https://raw.githubusercontent.com/muan/unicode-emoji-json/refs/heads/main/data-by-group.json"

-- :: UTILS ::
local function notify(msg, level)
    level = level or "low"
    os.execute("notify-send -u " .. level .. " -a 'Celestial Shade' '" .. msg .. "'")
end

-- :: SETUP PHASE ::
local function ensure_cache()
    local f = io.open(cache_file, "r")
    if f then
        f:close()
        return true -- Cache exists
    end

    if not os.execute("command -v jq > /dev/null 2>&1") then
        notify("Missing dependency: 'jq'", "critical")
        return false
    end

    notify("Downloading Emoji Database...")
    os.execute("mkdir -p " .. asset_dir)

    -- :: THE FIX ::
    -- The JSON is an Array of Groups. Each Group has an 'emojis' Array.
    -- We pipe: 
    -- 1. .[]          -> Unpack the array of groups
    -- 2. .emojis[]    -> Unpack the array of emojis inside each group
    -- 3. String Interp -> Format as "🤠  Name"
    local cmd = string.format(
        "curl -sL '%s' | jq -r '.[] | .emojis[] | \"\\(.emoji)  \\(.name)\"' > '%s'", 
        json_url, cache_file
    )
    
    if os.execute(cmd) then
        notify("Emoji list updated.")
        return true
    else
        notify("Failed to process emojis.", "critical")
        return false
    end
end

-- :: MAIN MENU ::
if not ensure_cache() then return end

-- Pipe the formatted text file into Rofi
-- -i for case insensitive search
local cmd = string.format("cat '%s' | rofi -dmenu -i -theme %s -p '😀  Emoji'", cache_file, rofi_conf)
local handle = io.popen(cmd)
local selection = handle:read("*a"):gsub("\n", "")
handle:close()

-- :: PROCESS SELECTION ::
if selection and selection ~= "" then
    -- Extract the emoji (first character(s) before space)
    local emoji = selection:match("^(%S+)")
    
    if emoji then
        os.execute(string.format("echo -n '%s' | wl-copy", emoji))
        notify("Copied: " .. emoji)
    end
end

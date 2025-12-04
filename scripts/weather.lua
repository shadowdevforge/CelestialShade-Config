#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: WEATHER MODULE
-- -----------------------------------------------------

local function exec(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
end

local function get_weather()
    -- 1. Check Internet
    local internet = os.execute("ping -c 1 8.8.8.8 > /dev/null 2>&1")
    if not internet then
        return '{"text": "Offline", "tooltip": "No internet connection", "class": "offline"}'
    end

    -- 2. Fetch Data (wttr.in)
    -- Format 1: emoji + temp (e.g., "☀️ +25°C")
    -- Format 4: Location + Temp + Wind (Tooltip)
    local text = exec("curl -s 'wttr.in/?format=1'")
    local tooltip = exec("curl -s 'wttr.in/?format=4'")

    -- 3. Sanitize
    -- Remove the '+' sign for a cleaner look ("+25°C" -> " 25°C")
    text = text:gsub("%+", " ")
    
    -- Escape quotes for JSON safety
    text = text:gsub('"', '\\"')
    tooltip = tooltip:gsub('"', '\\"')
    
    -- Collapse newlines in tooltip to avoid JSON errors
    tooltip = tooltip:gsub("\n", " ")

    -- 4. Output JSON
    return string.format('{"text": "%s", "tooltip": "%s", "class": "weather"}', text, tooltip)
end

print(get_weather())

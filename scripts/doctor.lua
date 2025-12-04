#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: SYSTEM DOCTOR
-- -----------------------------------------------------

local home = os.getenv("HOME")
local config_root = home .. "/.config/hypr"
local theme_root = config_root .. "/theme"

-- :: COLORS ::
local C = {
    reset = "\27[0m",
    green = "\27[32m",
    red   = "\27[31m",
    blue  = "\27[34m",
    bold  = "\27[1m"
}

-- :: HELPERS ::
local function check_cmd(cmd)
    return os.execute("command -v " .. cmd .. " > /dev/null 2>&1")
end

local function check_dir(path)
    local f = io.open(path, "r")
    if f then
        local _, _, code = f:read(1)
        f:close()
        return code == 21 -- Is a directory
    end
    -- Fallback check using ls
    return os.execute("[ -d '" .. path .. "' ]")
end

local function count_files(path)
    local handle = io.popen("ls -1 '" .. path .. "' 2>/dev/null | wc -l")
    local count = handle:read("*a")
    handle:close()
    return tonumber(count) or 0
end

local function log(status, msg)
    if status then
        print(string.format(" [%sOK%s] %s", C.green, C.reset, msg))
    else
        print(string.format(" [%sXX%s] %s", C.red, C.reset, msg))
    end
end

-- :: DIAGNOSTICS ::

print(C.blue .. C.bold .. ":: CELESTIAL SHADE DIAGNOSTICS ::" .. C.reset)
print("-------------------------------------")

local issues = 0

-- 1. Core Binaries
print(C.bold .. ":: Core Binaries" .. C.reset)
local deps = {"hyprland", "hyprshot", "waybar", "rofi", "swww-daemon", "mako", "hyprlock", "hypridle", "wlogout", "ghostty", "lua", "cliphist", "wl-copy", "jq"}
for _, dep in ipairs(deps) do
    if check_cmd(dep) then
        log(true, dep)
    else
        log(false, "Missing binary: " .. dep)
        issues = issues + 1
    end
end

-- 2. Fonts
print("\n" .. C.bold .. ":: Fonts" .. C.reset)
local font_check = os.execute("fc-list | grep -q 'JetBrainsMono Nerd Font'")
if font_check then
    log(true, "JetBrainsMono Nerd Font")
else
    log(false, "Missing Font: JetBrainsMono Nerd Font")
    issues = issues + 1
end

-- 3. Theme Engine
print("\n" .. C.bold .. ":: Theme Engine" .. C.reset)
local palette_count = count_files(theme_root .. "/palettes")
if palette_count > 0 then
    log(true, string.format("Detected %d Color Palettes", palette_count))
else
    log(false, "CRITICAL: No palettes found in " .. theme_root .. "/palettes")
    issues = issues + 1
end

-- 4. Wallpaper Vaults
print("\n" .. C.bold .. ":: Wallpaper Vaults" .. C.reset)
local handle = io.popen("ls -d " .. theme_root .. "/wallpapers/*/ 2>/dev/null")
local theme_dirs = {}
for line in handle:lines() do
    table.insert(theme_dirs, line)
end
handle:close()

if #theme_dirs > 0 then
    for _, dir in ipairs(theme_dirs) do
        local name = dir:match("([^/]+)/$")
        local count = count_files(dir)
        if count > 0 then
            log(true, string.format("Theme '%s': %d images", name, count))
        else
            print(string.format(" [%s!!%s] Theme '%s' is empty", C.red, C.reset, name))
        end
    end
else
    log(false, "No wallpaper directories found")
    issues = issues + 1
end

print("-------------------------------------")
if issues == 0 then
    print(C.green .. ":: SYSTEM HEALTHY. Ready for launch." .. C.reset)
else
    print(C.red .. string.format(":: %d ISSUES DETECTED. Please fix before launch.", issues) .. C.reset)
end

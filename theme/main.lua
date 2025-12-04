#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: UNIFIED THEME CONTROLLER
-- -----------------------------------------------------

local home = os.getenv("HOME")
local root = home .. "/.config/hypr/theme"
local palette_dir = root .. "/palettes"
local artifact_dir = root .. "/artifact"
local config_dir = home .. "/.config/hypr/config"
local state_file = root .. "/.current"

-- :: UTILITIES ::
local Utils = {}

function Utils.write_file(path, content)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

function Utils.read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content and content:match("^%s*(.-)%s*$") or nil
end

function Utils.list_palettes()
    local p = io.popen('find "' .. palette_dir .. '" -name "*.lua" -exec basename {} .lua \\;')
    local themes = {}
    for file in p:lines() do
        table.insert(themes, file)
    end
    p:close()
    table.sort(themes)
    return themes
end

function Utils.load_palette(name)
    local path = palette_dir .. "/" .. name .. ".lua"
    local chunk = loadfile(path)
    if not chunk then return nil end
    return chunk()
end

-- :: GENERATORS ::
local Gen = {}

-- 1. HYPRLAND & HYPRLOCK ($var = 0xff...)
function Gen.hyprland(t)
    local content = string.format([[
$bg_base    = 0xff%s
$bg_mantle  = 0xff%s
$fg_text    = 0xff%s
$primary    = 0xff%s
$secondary  = 0xff%s
$accent     = 0xff%s
$error      = 0xff%s

# Border Colors
$border_active   = $primary
$border_inactive = $bg_mantle

# Common aliases for Hyprlock compatibility
$text_color = $fg_text
$primary_accent = $primary
]], t.base, t.mantle, t.text, t.primary, t.secondary, t.accent, t.error)
    Utils.write_file(artifact_dir .. "/theme.conf", content)
end

-- 2. GTK/WAYBAR CSS (@define-color...)
function Gen.css(t)
    local content = string.format([[
@define-color bg_base #%s;
@define-color bg_mantle #%s;
@define-color fg_text #%s;
@define-color fg_sub #%s;
@define-color primary #%s;
@define-color secondary #%s;
@define-color accent #%s;
@define-color error #%s;
]], t.base, t.mantle, t.text, t.subtext or t.text, t.primary, t.secondary, t.accent, t.error)
    Utils.write_file(artifact_dir .. "/theme.css", content)
end

-- 3. ROFI (* { var: val }) - NEW!
function Gen.rofi(t)
    local content = string.format([[
* {
    bg-base:    #%s;
    bg-mantle:  #%s;
    fg-text:    #%s;
    fg-sub:     #%s;
    primary:    #%s;
    secondary:  #%s;
    accent:     #%s;
    error:      #%s;
}
]], t.base, t.mantle, t.text, t.subtext or t.text, t.primary, t.secondary, t.accent, t.error)
    Utils.write_file(artifact_dir .. "/theme.rasi", content)
end

-- 4. MAKO (Direct Config Injection)
function Gen.mako(t)
    local content = string.format([[
# CELESTIAL SHADE :: MAKO
layer=overlay
anchor=top-right
margin=15
padding=20
width=380
height=150
font=JetBrainsMono Nerd Font 11
border-size=2
border-radius=15
icons=1
max-icon-size=48
default-timeout=5000
background-color=#%sE6
text-color=#%s
border-color=#%s
progress-color=#%s
[urgency=low]
border-color=#%s
[urgency=normal]
border-color=#%s
[urgency=critical]
border-color=#%s
default-timeout=0
]], t.base, t.text, t.primary, t.primary, t.secondary, t.primary, t.error)
    
    -- Ensure dir exists
    os.execute("mkdir -p " .. config_dir .. "/mako")
    Utils.write_file(config_dir .. "/mako/config", content)
end

-- 5. GHOSTTY (Key=Value)
function Gen.ghostty(t)
    local content = string.format([[
# CELESTIAL SHADE :: GHOSTTY THEME
background = #%s
foreground = #%s
cursor-color = #%s
cursor-text = #%s
selection-background = #%s
selection-foreground = #%s

# Normal
palette = 0=#%s
palette = 1=#%s
palette = 2=#%s
palette = 3=#%s
palette = 4=#%s
palette = 5=#%s
palette = 6=#%s
palette = 7=#%s

# Bright
palette = 8=#%s
palette = 9=#%s
palette = 10=#%s
palette = 11=#%s
palette = 12=#%s
palette = 13=#%s
palette = 14=#%s
palette = 15=#%s
]], 
    t.base, t.text, 
    t.secondary, t.base, -- Cursor
    t.primary, t.base,   -- Selection
    
    -- Colors 0-7
    t.mantle, t.error, t.success, t.warning, 
    t.secondary, t.primary, t.accent, t.subtext,
    
    -- Colors 8-15 (Brights - mapped same or slightly tweaked if palette allowed)
    t.surface1 or t.mantle, t.error, t.success, t.warning,
    t.secondary, t.primary, t.accent, t.text
    )
    Utils.write_file(artifact_dir .. "/ghostty.conf", content)
end

-- :: CORE LOGIC ::

local function apply_theme(name)
    print(":: Applying Palette: " .. name)
    local palette = Utils.load_palette(name)
    if not palette then 
        print("Error: Palette not found") 
        return 
    end

    Utils.write_file(state_file, name)

    -- Generate All Artifacts
    Gen.hyprland(palette)
    Gen.css(palette)
    Gen.rofi(palette) 
    Gen.mako(palette)
    Gen.ghostty(palette)

    -- Reload Services
    os.execute("hyprctl reload")
    os.execute("pkill waybar; waybar -c " .. config_dir .. "/waybar/config.jsonc -s " .. config_dir .. "/waybar/style.css > /dev/null 2>&1 &")
    os.execute("makoctl reload")
    
    -- Update Wallpaper
    os.execute(home .. "/.config/hypr/theme/wallpaper.lua &")

    os.execute("notify-send -u low 'Celestial Shade' 'Theme set to " .. name:upper() .. "'")
end

local function launch_menu()
    local themes = Utils.list_palettes()
    local list_str = table.concat(themes, "\n")
    -- Ensure Rofi uses the config that imports our new theme.rasi
    local cmd = string.format("echo -e '%s' | rofi -dmenu -theme %s/rofi/config.rasi -p '  Theme'", list_str, config_dir)
    local handle = io.popen(cmd)
    local choice = handle:read("*a"):gsub("\n", "")
    handle:close()

    if choice and choice ~= "" then
        apply_theme(choice)
    end
end

-- :: ENTRY POINT ::
local arg1 = arg[1]

if arg1 == "--menu" then
    launch_menu()
elseif arg1 then
    apply_theme(arg1)
else
    local current = Utils.read_file(state_file) or "catppuccin"
    apply_theme(current)
end

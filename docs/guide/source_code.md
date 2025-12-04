# screenshot.lua
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

# weather.lua
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

# doctor.lua
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
local deps = {"hyprland", "waybar", "rofi", "swww-daemon", "mako", "hyprlock", "hypridle", "wlogout", "ghostty", "lua", "cliphist", "wl-copy", "jq"}
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

# emoji.lua
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

# cheatsheet.py
import curses
import os
import re

CONFIG_PATH = os.path.expanduser("~/.config/hypr/hyprland.conf")

def parse_config():
    binds = []
    main_mod = "SUPER"
    
    try:
        with open(CONFIG_PATH, 'r') as f:
            lines = f.readlines()
            
        for line in lines:
            line = line.strip()
            
            # Extract variable definitions for mod key
            if line.startswith("$mainMod"):
                parts = line.split('=')
                if len(parts) > 1:
                    main_mod = parts[1].strip()

            # Parse binds
            # Format: bind = MOD, KEY, ACTION, ARG # Comment
            if line.startswith("bind =") or line.startswith("bindm ="):
                # Separate comment if exists
                comment = ""
                if "#" in line:
                    parts = line.split("#", 1)
                    line = parts[0].strip()
                    comment = parts[1].strip()
                
                # Remove "bind =" prefix
                content = line.split("=", 1)[1].strip()
                tokens = [t.strip() for t in content.split(",")]
                
                if len(tokens) >= 2:
                    mods = tokens[0].replace("$mainMod", main_mod).replace("SHIFT", "SHFT")
                    key = tokens[1].upper()
                    
                    # Construct Action description
                    action = tokens[2] if len(tokens) > 2 else ""
                    arg = tokens[3] if len(tokens) > 3 else ""
                    
                    # If we have a comment, that's the best description
                    # If not, combine action + arg
                    desc = comment if comment else f"{action} {arg}"
                    
                    # Clean up exec commands for display
                    if desc.startswith("exec"):
                        desc = desc.replace("exec", "").strip()
                        if desc.startswith(","): desc = desc[1:].strip()
                        
                    binds.append({
                        "keys": f"{mods} + {key}",
                        "desc": desc
                    })
    except Exception as e:
        return [{"keys": "Error", "desc": str(e)}]

    return binds

def draw_menu(stdscr):
    # Setup
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()
    
    # Define colors based on terminal palette (Ghostty handles the actual hex)
    # Pair 1: Header (Cyan on Base)
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    # Pair 2: Key (Magenta/Pink)
    curses.init_pair(2, curses.COLOR_MAGENTA, -1)
    # Pair 3: Text (White)
    curses.init_pair(3, curses.COLOR_WHITE, -1)
    # Pair 4: Selected (Black on Green)
    curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_GREEN)

    binds = parse_config()
    current_row = 0
    
    while True:
        stdscr.clear()
        height, width = stdscr.getmaxyx()
        
        # Draw Header
        title = " :: CELESTIAL SHADE KEYMAPS :: "
        stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
        stdscr.addstr(1, (width - len(title)) // 2, title)
        stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)
        
        stdscr.addstr(2, 2, "-" * (width - 4), curses.color_pair(3))

        # Calculate scroll viewport
        max_lines = height - 5
        start_index = max(0, current_row - max_lines + 1)
        end_index = min(len(binds), start_index + max_lines)
        
        # Draw List
        for i in range(start_index, end_index):
            item = binds[i]
            y = 4 + (i - start_index)
            
            # Formatting
            key_str = f"{item['keys']:<20}"
            desc_str = item['desc'][:(width - 25)] # Truncate if too long
            
            if i == current_row:
                stdscr.attron(curses.color_pair(4))
                stdscr.addstr(y, 2, f" {key_str} {desc_str} ".ljust(width-4))
                stdscr.attroff(curses.color_pair(4))
            else:
                stdscr.attron(curses.color_pair(2) | curses.A_BOLD)
                stdscr.addstr(y, 2, key_str)
                stdscr.attroff(curses.color_pair(2) | curses.A_BOLD)
                
                stdscr.attron(curses.color_pair(3))
                stdscr.addstr(y, 24, desc_str)
                stdscr.attroff(curses.color_pair(3))

        # Draw Footer
        footer = " [UP/DOWN] Navigate  [Q] Quit "
        stdscr.addstr(height - 2, (width - len(footer)) // 2, footer, curses.color_pair(3) | curses.A_DIM)

        stdscr.refresh()

        # Input Handling
        key = stdscr.getch()
        
        if key == curses.KEY_UP and current_row > 0:
            current_row -= 1
        elif key == curses.KEY_DOWN and current_row < len(binds) - 1:
            current_row += 1
        elif key == ord('q') or key == 27: # q or ESC
            break

if __name__ == "__main__":
    curses.wrapper(draw_menu)

# clipboard.lua
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

# config.rasi
configuration {
    modi: "drun,run";
    show-icons: true;
    font: "JetBrainsMono Nerd Font Bold 12";
    display-drun: "   Apps ";
    display-run: "   Run ";
}

/* Import the colors generated by your Lua script */
@import "colors.rasi"

* {
    /* Reset defaults to prevent system theme bleeding */
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    width: 45%;
    transparency: "real";
    border: 2px;
    border-color: @selected;
    border-radius: 15px;
    background-color: @background;
}

mainbox {
    children: [ inputbar, listview ];
    padding: 20px;
    background-color: transparent;
}

/* --- SEARCH BAR --- */
inputbar {
    children: [ prompt, entry ];
    background-color: @background-alt;
    border-radius: 10px;
    margin: 0px 0px 15px 0px;
    padding: 12px;
}

prompt {
    background-color: transparent;
    text-color: @selected;
    font-weight: bold;
    padding: 0px 10px 0px 0px;
}

entry {
    background-color: transparent;
    text-color: @foreground;
    placeholder: "Search Celestial Shade...";
    placeholder-color: inherit;
}

/* --- LIST VIEW --- */
listview {
    lines: 8;
    background-color: transparent;
    spacing: 5px;
    scrollbar: false;
}

/* --- ELEMENTS (The Apps) --- */
element {
    padding: 10px;
    border-radius: 8px;
    background-color: transparent;
    text-color: @foreground;
    orientation: horizontal;
    children: [ element-icon, element-text ];
}

/* When an item is hovered/selected */
element selected {
    background-color: @selected;
    text-color: @background; /* Swaps text to dark for contrast */
}

/* --- WIDGET INHERITANCE FIX --- */
element-icon {
    size: 24px;
    background-color: transparent;
    text-color: inherit; /* Inherit color from element */
    padding: 0px 15px 0px 0px;
    cursor: inherit;
}

element-text {
    vertical-align: 0.5;
    background-color: transparent;
    text-color: inherit; /* Inherit color from element */
    highlight: underline;
    cursor: inherit;
}

# colors.rasi
/* Import the generated Rofi variables */
@import "../../theme/artifact/theme.rasi"

* {
    /* Use the variables defined in theme.rasi */
    /* Note: In Rofi, variables are used via @varname */
    
    /* Map generated variables to Rofi properties */
    background:     @bg-base;
    background-alt: @bg-mantle;
    foreground:     @fg-text;
    selected:       @primary;
    active:         @secondary;
    urgent:         @error;

    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
}

/* ... Rest of your config stays the same ... */

# config
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
background-color=#1e1e2eE6
text-color=#cdd6f4
border-color=#cba6f7
progress-color=#cba6f7
[urgency=low]
border-color=#89b4fa
[urgency=normal]
border-color=#cba6f7
[urgency=critical]
border-color=#f38ba8
default-timeout=0

# config.template
# -----------------------------------------------------
# CELESTIAL SHADE :: MAKO TEMPLATE
# -----------------------------------------------------

# :: PLACEMENT
layer=overlay
anchor=top-right
margin=15
padding=20
width=380
height=150

# :: LOOK & FEEL
font=JetBrainsMono Nerd Font 11
border-size=2
border-radius=15
icons=1
max-icon-size=48
default-timeout=5000
ignore-timeout=0

# :: COLORS (Injected)
background-color={{base}}E6
text-color={{text}}
border-color={{active}}

# :: PROGRESS BAR (Fixed)
progress-color={{active}}

# :: URGENCY LEVELS
[urgency=low]
border-color={{inactive}}
text-color={{subtext}}

[urgency=normal]
border-color={{active}}

[urgency=critical]
border-color={{error}}
default-timeout=0
background-color={{base}}FF

# style.css
/* -----------------------------------------------------
 * CELESTIAL SHADE :: UNREAL ENGINE
 * ----------------------------------------------------- */
@import "../../theme/artifact/theme.css";

* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
    transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
}

window#waybar {
    background: transparent;
    color: @fg_text;
}

tooltip {
    background: @bg_base;
    border: 1px solid @primary;
    border-radius: 12px;
}

/* -----------------------------------------------------
 * LEFT: WORKSPACES & STATS
 * ----------------------------------------------------- */

#custom-launcher {
    background: @bg_base;
    color: @accent;
    padding: 0px 16px;
    margin-right: 5px;
    border-radius: 16px;
    font-size: 18px;
    opacity: 0.9;
}
#custom-launcher:hover {
    background: @accent;
    color: @bg_base;
    box-shadow: 0 0 10px @accent;
}

#workspaces {
    background: alpha(@bg_base, 0.6);
    margin-right: 5px;
    padding: 5px;
    border-radius: 16px;
    border-bottom: 2px solid @bg_mantle;
}

#workspaces button {
    padding: 0 6px;
    color: @fg_sub;
    border-radius: 10px;
}

#workspaces button.active {
    color: @primary;
    background: alpha(@primary, 0.1);
    min-width: 40px; /* Expands active workspace */
    border-bottom: 2px solid @primary;
}

#workspaces button:hover {
    background: @bg_mantle;
    color: @fg_text;
}

/* Stats Group */
#cpu, #memory {
    background: alpha(@bg_base, 0.6);
    color: @fg_text;
    padding: 0 12px;
}

#cpu {
    border-radius: 16px 0 0 16px;
    margin-left: 5px;
}
#memory {
    border-radius: 0 16px 16px 0;
    border-left: 1px solid alpha(@fg_text, 0.1);
}

/* -----------------------------------------------------
 * CENTER: TIME & WEATHER
 * ----------------------------------------------------- */

#clock, #custom-weather {
    background: alpha(@bg_base, 0.8);
    color: @fg_text;
    padding: 2px 15px;
}

#clock {
    border-radius: 16px 0 0 16px;
    margin-right: 0;
    border-bottom: 2px solid @secondary;
    color: @secondary;
}

#custom-weather {
    border-radius: 0 16px 16px 0;
    margin-left: 0;
    border-bottom: 2px solid @accent;
    color: @accent;
}

/* -----------------------------------------------------
 * RIGHT: MEDIA & HARDWARE
 * ----------------------------------------------------- */

#mpris {
    background: alpha(@bg_base, 0.6);
    color: @primary;
    border-radius: 16px;
    padding: 0 15px;
    margin-right: 5px;
    font-weight: normal;
}

#mpris.paused {
    color: @fg_sub;
    font-style: italic;
}

/* Hardware Group */
#pulseaudio, #network, #battery {
    background: alpha(@bg_base, 0.6);
    color: @fg_text;
    padding: 0 12px;
}

#pulseaudio {
    border-radius: 16px 0 0 16px;
    color: @primary;
}

#network {
    color: @secondary;
}

#battery {
    border-radius: 0 16px 16px 0;
}

#battery.charging { color: @success; }
#battery.warning { color: @warning; }
#battery.critical { 
    color: @error;
    animation: blink 0.5s infinite alternate;
}

/* Tray */
#tray {
    background: alpha(@bg_base, 0.6);
    padding: 0 12px;
    border-radius: 16px;
    margin: 0 5px;
}

/* Power Button */
#custom-power {
    background: alpha(@error, 0.1);
    color: @error;
    padding: 0 14px;
    border-radius: 16px;
    margin-left: 5px;
    border-bottom: 2px solid @error;
}

#custom-power:hover {
    background: @error;
    color: @bg_base;
    box-shadow: 0 0 15px @error;
}

@keyframes blink {
    to { color: @bg_base; background: @error; }
}

/* -----------------------------------------------------
 * SCREENSHOT DRAWER
 * ----------------------------------------------------- */

/* The Main Pill Container */
#group-screenshot {
    background: alpha(@bg_base, 0.5); /* Solid background for the whole group */
    color: @accent;
    border-radius: 16px;
    margin: 0 5px;
    padding: 2px; /* Small padding creates a border-like effect */
    border: 1px solid @bg_mantle;
    transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
}

/* The Handle (Camera Icon) */
#custom-shot-icon {
    background: alpha(@bg_mantle, 0.5); /* Distinct background for handle */
    color: @accent;
    padding: 4px 12px;
    margin: 2px;
    border-radius: 14px;
    font-size: 16px;
}

/* The Children (Hidden buttons) */
.screenshot-child {
    background: transparent;
    color: @fg_text;
    padding: 0 10px;
    margin: 0 2px;
    border-radius: 12px;
}

/* Hover Effects for Children */
#custom-shot-region:hover,
#custom-shot-window:hover,
#custom-shot-full:hover {
    background: @accent;
    color: @bg_base;
    box-shadow: 0 0 10px alpha(@accent, 0.4);
}

/* Active State of the Drawer */
#group-screenshot.drawer-open {
    border-color: @accent;
    background: @bg_base; /* Darker when open to make icons pop */
}

#custom-cheatsheet {
    background: alpha(@bg_base, 0.6);
    color: @secondary; /* Blue/Cyan look */
    padding: 0 12px;
    margin: 0 5px;
    border-radius: 16px;
    font-size: 16px;
}

#custom-cheatsheet:hover {
    background: @secondary;
    color: @bg_base;
    box-shadow: 0 0 10px @secondary;
}

# config.jsonc
{
    "layer": "top",
    "position": "top",
    "height": 46,
    "margin-top": 10,
    "margin-left": 15,
    "margin-right": 15,
    "spacing": 0,

    // Load Modules
    "modules-left": ["custom/launcher", "hyprland/workspaces", "group/stats"],
    "modules-center": ["clock", "custom/weather"],
    "modules-right": ["mpris", "group/hardware", "custom/cheatsheet", "group/screenshot", "tray", "custom/power",],

    // :: GROUPS ::
    "group/stats": {
        "orientation": "horizontal",
        "modules": ["cpu", "memory"]
    },
    
    "group/hardware": {
        "orientation": "horizontal",
        "modules": ["pulseaudio", "network", "battery"]
    },

    // :: MODULES ::
    "custom/launcher": {
        "format": " ",
        "on-click": "rofi -show drun -theme ~/.config/hypr/config/rofi/config.rasi",
        "tooltip": false
    },

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "default": " ",
            "active": " 󰮯 ",
            "urgent": " "
        },
        "persistent-workspaces": { "1": [], "2": [], "3": [] },
        "on-click": "activate"
    },

    "cpu": {
        "format": "   {usage}%",
        "interval": 2
    },

    "memory": {
        "format": "   {}%",
        "interval": 2
    },

    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%A, %B %d}",
        "tooltip-format": "<tt>{calendar}</tt>",
        "calendar": {
            "mode": "year",
            "mode-mon-col": 3,
            "on-scroll": 1,
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "days": "<span color='#ecc6d9'><b>{}</b></span>",
                "weeks": "<span color='#99ffdd'><b>W{}</b></span>",
                "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
            }
        }
    },

    "custom/weather": {
        "format": "{}",
        "exec": "~/.config/hypr/scripts/weather.lua",
        "return-type": "json",
        "interval": 600
    },

    "mpris": {
        "format": "{player_icon} {title}",
        "format-paused": "{status_icon} <i>{title}</i>",
        "player-icons": {
            "default": "  ",
            "spotify": "  ",
            "firefox": "  "
        },
        "status-icons": {
            "paused": "  "
        },
        "max-length": 35
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "  ",
        "format-icons": { "default": ["  ", "  ", "  "] },
        "on-click": "pavucontrol"
    },

    "network": {
        "format-wifi": "  ",
        "format-ethernet": "󰈀  ",
        "format-disconnected": "󰖪  ",
        "tooltip-format": "{essid}",
        "on-click": "ghostty -e nmtui"
    },

    "battery": {
        "states": { "warning": 30, "critical": 15 },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-icons": [" ", " ", " ", " ", " "]
    },

    "tray": {
        "icon-size": 18,
        "spacing": 10
    },

      
    "custom/cheatsheet": {
        "format": " ",
        "tooltip": true,
        "tooltip-format": "Keybindings",
        // Launch Ghostty with a specific class so Hyprland can float it
        "on-click": "ghostty --class=cheatsheet -e python3 ~/.config/hypr/scripts/cheatsheet.py"
    },

      // :: SCREENSHOT GROUP (Drawer) ::
    "group/screenshot": {
        "orientation": "horizontal",
        "drawer": {
            "transition-duration": 500,
            "children-class": "screenshot-child",
            "transition-left-to-right": true // <--- EXPANDS TO RIGHT
        },
        "modules": [
            "custom/shot-icon",   // Handle (Visible)
            "custom/shot-region", // Children (Hidden until hover)
            "custom/shot-window",
            "custom/shot-full"
        ]
    },

    "custom/shot-icon": {
        "format": " ",
        "tooltip": true,
        "tooltip-format": "Screenshot Menu"
    },

    "custom/shot-region": {
        "format": "   ",
        "on-click": "~/.config/hypr/scripts/screenshot.lua region",
        "tooltip": true,
        "tooltip-format": "Capture Region"
    },

    "custom/shot-window": {
        "format": "   ",
        "on-click": "~/.config/hypr/scripts/screenshot.lua window",
        "tooltip": true,
        "tooltip-format": "Capture Window"
    },

    "custom/shot-full": {
        "format": "   ",
        "on-click": "~/.config/hypr/scripts/screenshot.lua output",
        "tooltip": true,
        "tooltip-format": "Capture Monitor"
    },

    "custom/power": {
        "format": "  ",
        "tooltip": false,
        "on-click": "wlogout --layout $HOME/.config/hypr/config/wlogout/layout --css $HOME/.config/hypr/config/wlogout/style.css --protocol layer-shell"
    },
}

# config
# -----------------------------------------------------
# CELESTIAL SHADE :: GHOSTTY CONFIG
# -----------------------------------------------------

# :: APPEARANCE
font-family = "JetBrainsMono Nerd Font"
font-size = 12
font-feature = -calt -liga
background-opacity = 0.80

# :: BEHAVIOR
command = /usr/bin/fish
confirm-close-surface = false
copy-on-select = true

# :: INTEGRATION
window-decoration = false
# This ensures it fits the "Master/Dwindle" tiling perfectly
resize-overlay = never

# :: CURSOR
cursor-style = block
cursor-style-blink = false

# :: THEME IMPORT
# This file is generated by theme/main.lua
config-file = ../../theme/artifact/ghostty.conf

# style.css
/* Import generated colors */
@import "../../theme/artifact/theme.css";

* {
    background-image: none;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 36px;
    box-shadow: none;
}

window {
    background-color: rgba(30, 30, 46, 0.9);
}

/* :: THE GRID CONTAINER :: */
#grid {
    background-color: transparent;
    /* Force buttons to align in the center */
    margin: 200px 100px;
}

/* :: BUTTONS :: */
button {
    background-color: @bg_mantle;
    color: @fg_text;
    border: 3px solid @bg_base;
    border-radius: 24px;
    
    /* Force exact size */
    margin: 20px;
    min-width: 120px;
    min-height: 120px;

    transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
    box-shadow: 0 10px 20px rgba(0,0,0,0.3);
}

/* :: HOVER :: */
button:focus, button:active, button:hover {
    background-color: @bg_base;
    color: @primary;
    border: 3px solid @primary;
    /* Scale effect */
    margin: 10px; /* Reduces margin to allow expansion without shifting layout */
    min-width: 140px;
    min-height: 140px;
    box-shadow: 0 0 30px alpha(@primary, 0.4);
}

/* :: CLEANUP :: */
#lock, #logout, #shutdown, #reboot, #suspend, #hibernate {
    margin: 20px;
}

# layout

{
    "label": "lock",
    "action": "hyprlock",
    "text": " ",
    "keybind": "l"
},
{
    "label": "logout",
    "action": "loginctl terminate-user $USER",
    "text": " ",
    "keybind": "e"
},
{
    "label": "shutdown",
    "action": "systemctl poweroff",
    "text": " ",
    "keybind": "s"
},
{
    "label": "reboot",
    "action": "systemctl reboot",
    "text": " ",
    "keybind": "r"
},
{
    "label": "suspend",
    "action": "systemctl suspend",
    "text": " ",
    "keybind": "u"
},
{
    "label": "hibernate",
    "action": "systemctl hibernate",
    "text": " ",
    "keybind": "h"
},


# theme.conf
$bg_base    = 0xff1e1e2e
$bg_mantle  = 0xff181825
$fg_text    = 0xffcdd6f4
$primary    = 0xffcba6f7
$secondary  = 0xff89b4fa
$accent     = 0xfff5c2e7
$error      = 0xfff38ba8

# Border Colors
$border_active   = $primary
$border_inactive = $bg_mantle

# Common aliases for Hyprlock compatibility
$text_color = $fg_text
$primary_accent = $primary

# theme.css
@define-color bg_base #1e1e2e;
@define-color bg_mantle #181825;
@define-color fg_text #cdd6f4;
@define-color fg_sub #a6adc8;
@define-color primary #cba6f7;
@define-color secondary #89b4fa;
@define-color accent #f5c2e7;
@define-color error #f38ba8;

# theme.rasi
* {
    bg-base:    #1e1e2e;
    bg-mantle:  #181825;
    fg-text:    #cdd6f4;
    fg-sub:     #a6adc8;
    primary:    #cba6f7;
    secondary:  #89b4fa;
    accent:     #f5c2e7;
    error:      #f38ba8;
}

# ghostty.conf
# CELESTIAL SHADE :: GHOSTTY THEME
background = #1e1e2e
foreground = #cdd6f4
cursor-color = #89b4fa
cursor-text = #1e1e2e
selection-background = #cba6f7
selection-foreground = #1e1e2e

# Normal
palette = 0=#181825
palette = 1=#f38ba8
palette = 2=#a6e3a1
palette = 3=#fab387
palette = 4=#89b4fa
palette = 5=#cba6f7
palette = 6=#f5c2e7
palette = 7=#a6adc8

# Bright
palette = 8=#45475a
palette = 9=#f38ba8
palette = 10=#a6e3a1
palette = 11=#fab387
palette = 12=#89b4fa
palette = 13=#cba6f7
palette = 14=#f5c2e7
palette = 15=#cdd6f4

# catppuccin.lua
return {
    -- Base
    base     = "1e1e2e",
    mantle   = "181825",
    crust    = "11111b",
    
    -- Text
    text     = "cdd6f4",
    subtext  = "a6adc8",
    
    -- Accents
    primary  = "cba6f7", -- Mauve
    secondary= "89b4fa", -- Blue
    accent   = "f5c2e7", -- Pink
    
    -- Status
    error    = "f38ba8",
    warning  = "fab387",
    success  = "a6e3a1",
    
    -- UI
    surface1 = "45475a"
}

# rosepine.lua
return {
    -- Base (The deep void)
    base     = "191724",
    mantle   = "1f1d2e",
    crust    = "1f1d2e",
    
    -- Text
    text     = "e0def4",
    subtext  = "908caa",
    
    -- Accents
    primary  = "c4a7e7", -- Iris (Purple)
    secondary= "ebbcba", -- Rose
    accent   = "31748f", -- Pine (Dark Cyan)
    
    -- Status
    error    = "eb6f92", -- Love
    warning  = "f6c177", -- Gold
    success  = "9ccfd8", -- Foam
    
    -- UI
    surface1 = "403d52"
}

# tokyonight.lua
return {
    -- Base
    base     = "1a1b26",
    mantle   = "16161e",
    crust    = "16161e",
    
    -- Text
    text     = "c0caf5",
    subtext  = "a9b1d6",
    
    -- Accents
    primary  = "7aa2f7", -- Blue
    secondary= "bb9af7", -- Magenta
    accent   = "7dcfff", -- Cyan
    
    -- Status
    error    = "f7768e",
    warning  = "e0af68",
    success  = "9ece6a",
    
    -- UI
    surface1 = "414868"
}

# nord.lua
return {
    -- Base (Polar Night)
    base     = "2e3440",
    mantle   = "242933",
    crust    = "1d232d",
    
    -- Text (Snow Storm)
    text     = "eceff4",
    subtext  = "d8dee9",
    
    -- Accents (Frost)
    primary  = "88c0d0", -- Cyan
    secondary= "81a1c1", -- Blue
    accent   = "5e81ac", -- Dark Blue
    
    -- Status (Aurora)
    error    = "bf616a",
    warning  = "ebcb8b",
    success  = "a3be8c",
    
    -- UI
    surface1 = "434c5e"
}

# dracula.lua
return {
    -- Base
    base     = "282a36",
    mantle   = "21222c",
    crust    = "191a21",
    
    -- Text
    text     = "f8f8f2",
    subtext  = "6272a4",
    
    -- Accents
    primary  = "bd93f9", -- Purple
    secondary= "ff79c6", -- Pink
    accent   = "8be9fd", -- Cyan
    
    -- Status
    error    = "ff5555",
    warning  = "f1fa8c",
    success  = "50fa7b",
    
    -- UI
    surface1 = "44475a"
}

# everforest.lua
return {
    -- Base (Hard Dark)
    base     = "272e33",
    mantle   = "2e383c",
    crust    = "1e2326",

    -- Text
    text     = "d3c6aa",
    subtext  = "9da9a0",

    -- Accents
    primary  = "a7c080", -- The Famous Soft Green
    secondary= "7fbbb3", -- Blue
    accent   = "e69875", -- Orange

    -- Status
    error    = "e67e80",
    warning  = "dbbc7f",
    success  = "a7c080",

    -- UI
    surface1 = "374145"
}

# gruvbox.lua
return {
    -- Base (Hard)
    base     = "282828",
    mantle   = "32302f",
    crust    = "1d2021",

    -- Text
    text     = "ebdbb2",
    subtext  = "a89984",

    -- Accents
    primary  = "b8bb26", -- RETRO GREEN (Primary Focus)
    secondary= "fabd2f", -- Yellow
    accent   = "d3869b", -- Purple

    -- Status
    error    = "fb4934",
    warning  = "fe8019",
    success  = "b8bb26",

    -- UI
    surface1 = "504945"
}

# synthwave.lua
return {
    -- Base (Deep Raisin/Purple)
    base     = "262335", -- raisin0
    mantle   = "2e2a4f", -- raisin1
    crust    = "262335", -- reusing base as darkest

    -- Text (Bluish White)
    text     = "fbf9ff", -- white
    subtext  = "a2c7e5", -- white_bluish

    -- Accents (Neon)
    primary  = "ff7edb", -- pink
    secondary= "3bf4fb", -- cyan
    accent   = "ffe347", -- yellow

    -- Status
    error    = "fe4450", -- red
    warning  = "f39237", -- carrot
    success  = "72f1b8", -- green_bright

    -- UI
    surface1 = "423e77"  -- raisin3 (Lighter for borders/panels)
}

# .current
catppuccin
# .wall_index
gruvbox=1
catppuccin=2
rosepine=1
everforest=5
nord=5
dracula=1
synthwave=3
tokyonight=1

# wallpaper.lua
#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: WALLPAPER CONTROLLER (Sequential)
-- -----------------------------------------------------

local home = os.getenv("HOME")
local theme_root = home .. "/.config/hypr/theme"
local wall_root = theme_root .. "/wallpapers"
local state_file = theme_root .. "/.current"       -- Stores "catppuccin", "rosepine"
local index_file = theme_root .. "/.wall_index"    -- Stores current index per theme

local Utils = {}

function Utils.read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content and content:match("^%s*(.-)%s*$") or nil
end

function Utils.write_file(path, content)
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    end
end

-- Load the index table (simple serialization)
function Utils.load_indices()
    local content = Utils.read_file(index_file)
    if not content then return {} end
    local t = {}
    for k, v in string.gmatch(content, "(%w+)=(%d+)") do
        t[k] = tonumber(v)
    end
    return t
end

-- Save the index table
function Utils.save_indices(t)
    local str = ""
    for k, v in pairs(t) do
        str = str .. k .. "=" .. v .. "\n"
    end
    Utils.write_file(index_file, str)
end

function Utils.get_wallpapers(theme)
    local dir = wall_root .. "/" .. theme
    local files = {}
    -- Find images, sort by name to ensure 1.png -> 2.png order
    local p = io.popen('find "' .. dir .. '" -type f \\( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \\) | sort -V')
    if not p then return {} end
    
    for file in p:lines() do
        table.insert(files, file)
    end
    p:close()
    return files
end

-- :: CORE LOGIC ::

local function run()
    -- 1. Get Current Theme
    local current_theme = Utils.read_file(state_file) or "catppuccin"
    
    -- 2. Get Wallpapers
    local wallpapers = Utils.get_wallpapers(current_theme)
    local total = #wallpapers
    
    if total == 0 then
        os.execute("notify-send -u critical 'Wallpaper Error' 'No images found in theme/" .. current_theme .. "'")
        return
    end

    -- 3. Calculate Next Index
    local indices = Utils.load_indices()
    local current_idx = indices[current_theme] or 0
    
    -- Loop logic: (0 -> 1), (1 -> 2) ... (5 -> 1)
    local next_idx = (current_idx % total) + 1
    
    -- 4. Apply Wallpaper
    local target_img = wallpapers[next_idx]
    
    os.execute("ln -sf '" .. target_img .. "' '" .. wall_root .. "/.current_image'")

    -- SWWW Transition (Smooth fade)
    local cmd = string.format("swww img '%s' --transition-type fade --transition-fps 60 --transition-duration 2", target_img)
    os.execute(cmd .. " &")
    
    -- 5. Update State
    indices[current_theme] = next_idx
    Utils.save_indices(indices)
    
    -- 6. Notify
    -- Extract filename for display
    local filename = target_img:match("^.+/(.+)$")
    os.execute(string.format("notify-send -u low -a 'Celestial Wallpaper' 'Theme: %s' 'Image: %s'", current_theme:upper(), filename))
end

run()

# main.lua
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

# hyprlock.conf
# -----------------------------------------------------
# CELESTIAL SHADE :: LOCK SCREEN
# -----------------------------------------------------

# Source the generated theme artifact
source = ~/.config/hypr/theme/artifact/theme.conf

general {
    no_fade_in = false
    grace = 0
    disable_loading_bar = true
}

background {
    monitor =
    # Uses the current wallpaper defined by the wallpaper controller
    path = ~/.config/hypr/theme/wallpapers/.current_image
    # Fallback color
    color = $bg_base

    # Blur effect for the "frosted glass" look
    blur_passes = 3
    blur_size = 7
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
}

# :: INPUT FIELD ::
input-field {
    monitor =
    size = 300, 50
    outline_thickness = 2
    dots_size = 0.2
    dots_spacing = 0.2
    dots_center = true
    
    # Theme Colors
    outer_color = $primary
    inner_color = $bg_base
    font_color = $fg_text
    
    fade_on_empty = false
    font_family = JetBrainsMono Nerd Font
    placeholder_text = Enter Password...
    hide_input = false
    position = 0, -120
    halign = center
    valign = center
}

# :: CLOCK (HOURS) ::
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H")"
    color = $primary
    shadow_passes = 1
    shadow_boost = 0.5
    font_size = 150
    font_family = JetBrainsMono Nerd Font ExtraBold
    position = 0, 150
    halign = center
    valign = center
}

# :: CLOCK (MINUTES) ::
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%M")"
    color = $fg_text
    font_size = 150
    font_family = JetBrainsMono Nerd Font ExtraBold
    position = 0, -00
    halign = center
    valign = center
}

# :: DATE ::
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%A, %B %d")"
    color = $fg_text
    font_size = 18
    font_family = JetBrainsMono Nerd Font
    position = 0, -80
    halign = center
    valign = center
}

# :: USER PROMPT ::
label {
    monitor =
    text = Hi there, $USER
    color = $fg_text
    font_size = 14
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, -180
    halign = center
    valign = center
}

# hyprland.conf
# -----------------------------------------------------
# CELESTIAL SHADE :: CORE CONFIGURATION
# -----------------------------------------------------

# :: PATHS & VARIABLES
$celestial_home = $HOME/.config/hypr
$scripts = $celestial_home/scripts
$conf_dir = $celestial_home/config
$wlogout = wlogout --layout $HOME/.config/hypr/config/wlogout/layout --css $HOME/.config/hypr/config/wlogout/style.css --protocol layer-shell
$wallpaper = $celestial_home/theme/wallpaper.lua 
$theme_menu = $celestial_home/theme/main.lua --menu
$screenshot = $celestial_home/scripts/screenshot.lua
$clipboard = $celestial_home/scripts/clipboard.lua
$emoji = $celestial_home/scripts/emoji.lua



# :: THEME IMPORT
# Dynamically generated by theme/main.lua
source = $celestial_home/theme/artifact/theme.conf

# :: PREFERRED APPS
$terminal = ghostty --config-file=$conf_dir/ghostty/config
$fileManager = thunar
$menu = rofi -show drun -theme $conf_dir/rofi/config.rasi
$browser = firedragon

# :: MONITORS
monitor = ,preferred,auto,1

# :: AUTOSTART
# Initialize Ecosystem (Runs main.lua to regenerate configs on boot)
exec-once = $celestial_home/theme/main.lua
exec-once = swww-daemon --format xrgb
exec-once = hypridle

# Interface
exec-once = waybar -c $conf_dir/waybar/config.jsonc -s $conf_dir/waybar/style.css
exec-once = mako -c $conf_dir/mako/config

exec = wl-paste --type text --watch cliphist store &
exec = wl-paste --type image --watch cliphist store &

# :: ENVIRONMENT
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = CELESTIAL_CONFIG,$conf_dir

# :: LOOK AND FEEL
general {
    gaps_in = 6
    gaps_out = 20
    border_size = 2

    # New Variable Names from theme.conf
    col.active_border = $border_active
    col.inactive_border = $border_inactive

    layout = dwindle 
    resize_on_border = false
    allow_tearing = false
}

decoration {
    rounding = 12

    active_opacity = 0.96
    inactive_opacity = 0.90

    shadow {
        enabled = true
        range = 15
        render_power = 3
        color = rgba(0,0,0,0.3)
    }

    blur {
        enabled = true
        size = 4
        passes = 3
        vibrancy = 0.1696
        ignore_opacity = true
        new_optimizations = true
    }
}

# :: ANIMATIONS
animations {
    enabled = true

    bezier = cozy, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0, 0, 1, 1
    bezier = quick, 0.15, 0, 0.1, 1

    animation = windows, 1, 5, cozy, popin 80%
    animation = windowsOut, 1, 5, cozy, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 4, default
    animation = workspaces, 1, 6, cozy, slide
}

# :: LAYOUTS
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    orientation = left 
    mfact = 0.55
    new_status = slave
    new_on_top = true
    allow_small_split = false
    special_scale_factor = 0.8
    inherit_fullscreen = true
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    font_family = "JetBrainsMono Nerd Font"
}

# :: INPUT
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0

    touchpad {
        natural_scroll = true
        scroll_factor = 0.5
    }
}

# :: KEYBINDINGS
$mainMod = SUPER

# Applications
bind = $mainMod, Return, exec, $terminal
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, Space, exec, $menu
bind = $mainMod, B, exec, $browser
bind = $mainMod, Backspace, exec, $wlogout 
bind = $mainMod, N, exec, makoctl dismiss
bind = $mainMod SHIFT, N, exec, makoctl restore

# Custom scripts
bind = $mainMod, W, exec, $wallpaper 
bind = $mainMod, T, exec, $theme_menu
bind = $mainMod, Print, exec, $screenshot
bind = $mainMod SHIFT, V, exec, $clipboard
bind = $mainMod, period, exec, $emoji

# Window Management
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, V, togglefloating,
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Mouse Interaction
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Hardware Keys
bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = ,XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = ,XF86MonBrightnessDown, exec, brightnessctl set 5%-


# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move to Workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Special Workspace
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic


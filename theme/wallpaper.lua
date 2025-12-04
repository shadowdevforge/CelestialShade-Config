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

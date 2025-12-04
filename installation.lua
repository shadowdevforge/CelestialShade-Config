#!/usr/bin/env lua
-- -----------------------------------------------------
-- CELESTIAL SHADE :: INSTALLATION WIZARD
-- -----------------------------------------------------
-- Author: shadowdevforge
-- Version: 1.0.0

local config = {
    repo_url = "https://github.com/shadowdevforge/CelestialShade-Config",
    target_dir = os.getenv("HOME") .. "/.config/hypr",
    log_file = "csinstaller.log",
    
    -- Core Dependencies (Arch Names)
    packages = {
        "hyprland", "waybar", "rofi", "mako", "hyprlock", "hypridle", 
        "wlogout", "cliphist", "wl-clipboard", "jq", 
        "ttf-jetbrains-mono-nerd", "git", "base-devel", "curl", "ghostty"
        -- Note: swww usually requires AUR, handled by AUR helper logic
    },
    
    aur_packages = {
        "swww", "ghostty-git" -- Fallback if ghostty not in repos
    }
}

-- =====================================================
-- :: 1. UTILITIES & THEME (Catppuccin Mocha)
-- =====================================================
local C = {
    reset = "\27[0m",
    bold  = "\27[1m",
    red   = "\27[38;2;243;139;168m", -- Red
    green = "\27[38;2;166;227;161m", -- Green
    blue  = "\27[38;2;137;180;250m", -- Blue
    mauve = "\27[38;2;203;166;247m", -- Mauve
    text  = "\27[38;2;205;214;244m", -- Text
    sub   = "\27[38;2;166;173;200m", -- Subtext
}

-- =====================================================
-- :: 2. CLASS: LOGGER
-- =====================================================
local Logger = {}
Logger.__index = Logger

function Logger:new(file_path)
    local obj = { file = file_path }
    -- Clear previous log
    local f = io.open(file_path, "w")
    if f then 
        f:write(":: CELESTIAL SHADE INSTALL LOG ::\n" .. os.date() .. "\n\n")
        f:close() 
    end
    setmetatable(obj, self)
    return obj
end

function Logger:log_to_file(type, msg)
    local f = io.open(self.file, "a")
    if f then
        f:write(string.format("[%s] [%s] %s\n", os.date("%H:%M:%S"), type, msg))
        f:close()
    end
end

function Logger:info(msg)
    print(C.blue .. " :: " .. C.text .. msg .. C.reset)
    self:log_to_file("INFO", msg)
end

function Logger:success(msg)
    print(C.green .. " [OK] " .. C.text .. msg .. C.reset)
    self:log_to_file("SUCCESS", msg)
end

function Logger:warn(msg)
    print(C.mauve .. " [!] " .. C.text .. msg .. C.reset)
    self:log_to_file("WARN", msg)
end

function Logger:error(msg)
    print(C.red .. " [X] " .. C.text .. msg .. C.reset)
    self:log_to_file("ERROR", msg)
end

-- =====================================================
-- :: 3. CLASS: SYSTEM (Shell Interaction)
-- =====================================================
local System = {}
System.__index = System

function System:new(dry_run, logger)
    local obj = { dry = dry_run, log = logger }
    setmetatable(obj, self)
    return obj
end

function System:exec(cmd, ignore_error)
    self.log:log_to_file("EXEC", cmd)
    
    if self.dry then
        print(C.sub .. "    [DRY] " .. cmd .. C.reset)
        return true
    end

    local success = os.execute(cmd)
    if not success and not ignore_error then
        return false
    end
    return true
end

function System:capture(cmd)
    if self.dry then return "" end
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result:gsub("^%s*(.-)%s*$", "%1")
end

function System:check_distro()
    local os_release = self:capture("cat /etc/os-release")
    if os_release:find("Arch Linux") or os_release:find("EndeavourOS") or os_release:find("ArcoLinux") then
        self.log:success("Compatible Distribution detected (Arch-based).")
        return true
    else
        self.log:warn("Non-Arch distribution detected. Dependencies might fail.")
        return false
    end
end

function System:cache_sudo()
    self.log:info("Requesting Sudo Access...")
    if self.dry then return true end
    return os.execute("sudo -v")
end

-- =====================================================
-- :: 4. CLASS: INSTALLER (Logic Core)
-- =====================================================
local Installer = {}
Installer.__index = Installer

function Installer:new(sys, log)
    local obj = { sys = sys, log = log, helper = "pacman" }
    setmetatable(obj, self)
    return obj
end

function Installer:detect_aur()
    if self.sys:capture("command -v paru") ~= "" then
        self.helper = "paru"
    elseif self.sys:capture("command -v yay") ~= "" then
        self.helper = "yay"
    else
        self.log:warn("No AUR helper found. Attempting to bootstrap 'yay'...")
        if not self.sys.dry then
            self.sys:exec("sudo pacman -S --needed --noconfirm git base-devel")
            self.sys:exec("git clone https://aur.archlinux.org/yay.git /tmp/yay")
            self.sys:exec("cd /tmp/yay && makepkg -si --noconfirm")
            self.helper = "yay"
        end
    end
    self.log:info("Package Manager: " .. self.helper)
end

function Installer:backup()
    self.log:info("Checking for existing configuration...")
    local check = self.sys:capture("ls -d " .. config.target_dir .. " 2>/dev/null")
    
    if check ~= "" then
        local backup_path = config.target_dir .. ".bak." .. os.time()
        self.log:warn("Existing config found. Backing up to: " .. backup_path)
        self.sys:exec("mv " .. config.target_dir .. " " .. backup_path)
    end
end

function Installer:install_deps()
    self.log:info("Installing Core Packages...")
    local pkg_str = table.concat(config.packages, " ")
    
    -- Install Repo Packages
    local cmd = ""
    if self.helper == "pacman" then
        cmd = "sudo pacman -S --needed --noconfirm " .. pkg_str
    else
        cmd = self.helper .. " -S --needed --noconfirm " .. pkg_str
    end
    
    self.sys:exec(cmd)

    -- Attempt AUR Packages (swww, etc)
    self.log:info("Installing AUR Packages...")
    local aur_str = table.concat(config.aur_packages, " ")
    if self.helper ~= "pacman" then
        self.sys:exec(self.helper .. " -S --needed --noconfirm " .. aur_str, true)
    else
        self.log:error("Cannot install AUR packages ("..aur_str..") without helper.")
    end
end

function Installer:finalize()
    self.log:info("Setting executable permissions...")
    self.sys:exec("chmod +x " .. config.target_dir .. "/scripts/*.lua")
    self.sys:exec("chmod +x " .. config.target_dir .. "/theme/*.lua")
    
    -- Initial Theme Generation
    self.log:info("Compiling initial theme artifacts...")
    self.sys:exec("lua " .. config.target_dir .. "/theme/main.lua catppuccin")
end

-- =====================================================
-- :: 5. CLASS: DOCTOR (Diagnostics)
-- =====================================================
local Doctor = {}
Doctor.__index = Doctor

function Doctor:new(sys, log)
    local obj = { sys = sys, log = log }
    setmetatable(obj, self)
    return obj
end

function Doctor:run()
    print("\n" .. C.blue .. C.bold .. ":: SYSTEM DOCTOR DIAGNOSTICS ::" .. C.reset)
    print(C.sub .. "-------------------------------------" .. C.reset)
    
    local missing = 0
    local binaries = config.packages
    -- Flatten aur packages into check list
    for _, p in ipairs(config.aur_packages) do table.insert(binaries, p) end

    -- 1. Check Binaries (Simplified logic: package name ~= binary name always, but close enough for check)
    -- We check key binaries explicitly
    local tools = {"hyprland", "waybar", "rofi", "mako", "swww-daemon", "lua", "cliphist"}
    
    for _, tool in ipairs(tools) do
        if self.sys:capture("command -v " .. tool) ~= "" then
            self.log:success("Found binary: " .. tool)
        else
            self.log:error("Missing binary: " .. tool)
            missing = missing + 1
        end
    end

    -- 2. Check Directories
    local theme_path = config.target_dir .. "/theme"
    if self.sys:capture("[ -d " .. theme_path .. " ] && echo yes") == "yes" then
        self.log:success("Theme Directory Structure OK")
    else
        self.log:error("Theme Directory Missing!")
        missing = missing + 1
    end

    print(C.sub .. "-------------------------------------" .. C.reset)
    if missing == 0 then
        self.log:success("SYSTEM HEALTHY. Ready for launch.")
    else
        self.log:warn(missing .. " Issues detected. Check log.")
    end
end

-- =====================================================
-- :: 6. MAIN EXECUTION PIPELINE
-- =====================================================

local function main()
    -- Check Args
    local dry_run = false
    for _, arg in ipairs(arg) do
        if arg == "--dry-run" then dry_run = true end
    end

    -- Header
    print(C.mauve .. [[


 ██████╗███████╗██╗     ███████╗███████╗████████╗██╗ █████╗ ██╗     
██╔════╝██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔══██╗██║     
██║     █████╗  ██║     █████╗  ███████╗   ██║   ██║███████║██║     
██║     ██╔══╝  ██║     ██╔══╝  ╚════██║   ██║   ██║██╔══██║██║     
╚██████╗███████╗███████╗███████╗███████║   ██║   ██║██║  ██║███████╗
 ╚═════╝╚══════╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝
                                                                    
            ███████╗██╗  ██╗ █████╗ ██████╗ ███████╗                
            ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔════╝                
            ███████╗███████║███████║██║  ██║█████╗                  
            ╚════██║██╔══██║██╔══██║██║  ██║██╔══╝                  
            ███████║██║  ██║██║  ██║██████╔╝███████╗                
            ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝                
                                                                   
    ]] .. C.reset)
    print(C.bold .. "            :: Minimal & Cozy Hyprland Ecosystem ::   " .. C.reset .. "\n")

    -- Init
    local logger = Logger:new(config.log_file)
    local sys = System:new(dry_run, logger)
    local installer = Installer:new(sys, logger)
    local doctor = Doctor:new(sys, logger)

    if dry_run then logger:warn("RUNNING IN DRY-RUN MODE") end

    -- Pipeline
    sys:check_distro()
    sys:cache_sudo()
    
    installer:detect_aur()
    installer:backup()
    installer:install_deps()
    installer:finalize()

    -- Post-Install Checks
    doctor:run()

    -- Upsell / Greeting
    print("\n" .. C.green .. C.bold .. ":: INSTALLATION COMPLETE ::" .. C.reset)
    print(C.text .. "You can start Hyprland by typing: " .. C.bold .. "Hyprland" .. C.reset)
    print("\n" .. C.sub .. "Need more tools? (Browsers, IDEs, etc?)")
    print(C.mauve .. "Check out ShadeInstaller by shadowdevforge:" .. C.reset)
    print(C.sub .. "curl -O https://raw.githubusercontent.com/shadowdevforge/ShadeInstaller/refs/heads/master/install.lua")
    print(C.sub .. "lua install.lua")
end

main()

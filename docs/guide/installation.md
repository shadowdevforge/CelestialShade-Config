# 📥 Installation Guide

Celestial Shade includes a robust, Object-Oriented Lua installer designed to handle Arch Linux (and derivatives) dependency management automatically.

## The Installer Script

The `installation.lua` script is the entry point. It performs the following operations:
1.  **Dependency Check:** Identifies Package Manager (`pacman`, `yay`, or `paru`).
2.  **Backup:** Safely moves existing `~/.config/hypr` configurations.
3.  **Hydration:** Installs core packages (`hyprland`, `waybar`, `ghostty`, etc.).
4.  **Compilation:** Runs the Theme Engine for the first time to generate artifacts.

### Standard Install

```bash
# 1. Clone the repository
git clone https://github.com/shadowdevforge/CelestialShade-Config ~/.config/hypr

# 2. Enter directory
cd ~/.config/hypr

# 3. Run the Lua Installer
lua installation.lua
```

### Dry Run (Simulation)
If you want to see exactly what commands will be executed without actually changing your system:
```bash
lua installation.lua --dry-run
```

## Post-Installation

Once the installer finishes, it triggers the **System Doctor**. You can run this diagnostics tool manually at any time to verify the health of your environment.

```bash
lua ~/.config/hypr/scripts/doctor.lua
```

**Output Example:**
```text
:: CELESTIAL SHADE DIAGNOSTICS ::
-------------------------------------
 [OK] hyprland
 [OK] waybar
 [OK] swww-daemon
 [OK] JetBrainsMono Nerd Font
 [OK] Detected 7 Color Palettes
:: SYSTEM HEALTHY. Ready for launch.
--- 

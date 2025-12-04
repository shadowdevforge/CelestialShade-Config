# 🩺 System Doctor

Celestial Shade includes a built-in diagnostic tool written in Lua (`scripts/doctor.lua`). 

It verifies that your system has all the necessary dependencies, fonts, and directory structures required for the ecosystem to function correctly. It is your first line of defense against broken configurations.

## Usage

If something looks wrong (icons missing, bars not loading, scripts failing), run the doctor immediately:

```bash
lua ~/.config/hypr/scripts/doctor.lua
```

## What it Checks

The doctor performs four phases of diagnostics:

### 1. Core Binaries
Checks for the existence of essential executables in your `$PATH`:
- **Core UI:** `hyprland`, `waybar`, `rofi`, `hyprlock`, `wlogout`
- **Daemons:** `swww-daemon` (Wallpapers), `mako` (Notifications), `hypridle`
- **Utilities:** `cliphist`, `wl-copy`, `jq` (JSON parsing for Emojis), `lua`
- **Terminal:** `ghostty`

### 2. Typography
Verifies that **JetBrainsMono Nerd Font** is installed and recognized by `fc-list`. 
*   *Why?* Without this, icons in Waybar, Rofi, and the Terminal will appear as broken rectangles ( tofu `□` ).

### 3. Theme Engine
Ensures the `theme/palettes/` directory exists and contains valid `.lua` palette files. If this fails, the Lua compiler cannot generate configs.

### 4. Wallpaper Vaults
Scans `theme/wallpapers/` to ensure every theme folder (e.g., `catppuccin`, `synthwave`) exists and contains images.

---

## Example Output

When running successfully, you will see a green report:

```text
:: CELESTIAL SHADE DIAGNOSTICS ::
-------------------------------------
:: Core Binaries
 [OK] hyprland
 [OK] waybar
 [OK] rofi
 [OK] swww-daemon
 ...

:: Fonts
 [OK] JetBrainsMono Nerd Font

:: Theme Engine
 [OK] Detected 8 Color Palettes

:: Wallpaper Vaults
 [OK] Theme 'catppuccin': 5 images
 [OK] Theme 'rosepine': 3 images
 [OK] Theme 'synthwave': 3 images
-------------------------------------
:: SYSTEM HEALTHY. Ready for launch.
```

## Troubleshooting

### `[X] MISSING: <binary>`
If a binary is missing, install it via your package manager.

```bash
# Example for Arch Linux
sudo pacman -S package_name
# Or via AUR (for swww, etc)
yay -S package_name
```

### `[X] MISSING: JetBrainsMono Nerd Font`
This is the most common error. Install the nerd font package:

```bash
sudo pacman -S ttf-jetbrains-mono-nerd
```

### `[!] Theme 'x' is empty`
If a wallpaper folder is empty, the wallpaper engine will fail when switching to that theme. Add `.png` or `.jpg` images to:
`~/.config/hypr/theme/wallpapers/<theme_name>/`

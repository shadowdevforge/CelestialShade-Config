# 🎨 Theming System

Celestial Shade currently ships with **8 Universal Palettes**:
`Catppuccin`, `Rose Pine`, `Tokyo Night`, `Nord`, `Dracula`, `Gruvbox`, `Synthwave`, and `Everforest`.

## Switching Themes

You can switch themes instantly without restarting your session.

1.  Press **`Super + T`**.
2.  Select a theme from the Rofi menu.
3.  The Engine will:
    *   Regenerate all config artifacts.
    *   Reload Waybar, Mako, and Hyprland.
    *   Switch to the correct wallpaper folder.

## The Wallpaper Controller

The wallpaper logic is **Stateful**. It resides in `theme/wallpaper.lua`.

*   **Structure:** Wallpapers are stored in `theme/wallpapers/<theme_name>/`.
*   **Sequential Loop:** The system indexes files numerically (e.g., `1.png`, `2.png`).
*   **Memory:** If you are on Image #3 in *Synthwave* and switch to *Nord*, then switch back to *Synthwave* later, it remembers you were on Image #3.

To cycle wallpapers manually, press **`Super + W`**.

## Creating a New Palette

To add your own theme, simply add a Lua file to `theme/palettes/`.

**Example:** `theme/palettes/mytheme.lua`

```lua
return {
    -- Backgrounds
    base     = "000000", -- Hex without #
    mantle   = "111111",
    
    -- Foreground
    text     = "ffffff",
    
    -- Accents
    primary  = "ff0000",
    secondary= "00ff00",
    accent   = "0000ff",
    
    -- Status
    error    = "ff0000",
    warning  = "ffff00",
    success  = "00ff00"
}
```

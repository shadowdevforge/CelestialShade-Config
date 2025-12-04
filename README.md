<div align="center">

# Celestial Shade

**Minimal and Cozy by default. Powerful when needed.**

![Lua](https://img.shields.io/badge/Engine-Lua_5.4-2d2d3a?style=for-the-badge&logo=lua&logoColor=blue)
![Hyprland](https://img.shields.io/badge/Compositor-Hyprland-2d2d3a?style=for-the-badge&logo=archlinux&logoColor=cba6f7)
![Catppuccin](https://img.shields.io/badge/Aesthetic-Catppuccin-2d2d3a?style=for-the-badge&logo=catppuccin&logoColor=f5c2e7)

<br/>

![Screenshot](docs/hero.png)

<br/>

## 📚 [Read the Documentation](https://shadowdevforge.github.io/CelestialShade-Config/)

**Full installation guide, customization details, and API references are available on official site.**

[**shadowdevforge.github.io/CelestialShade-Config**](https://shadowdevforge.github.io/CelestialShade-Config/)

</div>

---

## 💎 Philosophy

**Celestial Shade** is not just a dotfiles repository; it is a **Desktop Environment** built on Hyprland.

It rejects the standard "shell script spaghetti" found in most configurations in favor of a robust **Lua Object-Oriented Architecture**.

### ✨ Key Features

- **🔮 The Lua Engine**: A central compiler (`main.lua`) that reads raw data tables and generates valid config artifacts for Hyprland, Waybar, Rofi, and Ghostty instantly.
- **🏝️ Dynamic Islands**: A reactive Waybar configuration with expanding drawers for screenshots, power management, and dashboards.
- **🧠 State Awareness**: The wallpaper engine has memory. It remembers exactly which image you were using for *each* specific theme.
- **⚡ Native Performance**: Zero reliance on heavy Python/Node daemons for UI. Everything is native C++ or lightweight Lua.
- **🎨 8 Universal Themes**: Switch instantly between Catppuccin, Rose Pine, Nord, Synthwave, and more without reloading the OS.

## 🚀 Quick Start

For detailed instructions, [visit the documentation](https://shadowdevforge.github.io/CelestialShade-Config/guide/installation).

**One-line installation (Arch Linux):**

```bash
# 1. Clone the repository
git clone https://github.com/shadowdevforge/CelestialShade-Config ~/.config/hypr

# 2. Enter directory
cd ~/.config/hypr

# 3. Run the Lua Installer
lua installation.lua
```

## ⌨️ Quick Keybindings

| Key | Action |
| :--- | :--- |
| `Super + T` | **Theme Switcher** (Rofi Menu) |
| `Super + W` | **Next Wallpaper** (Cycles current theme folder) |
| `Super + Return` | Open Terminal (Ghostty) |
| `Super + Space` | Open App Launcher |
| `Super + Shift + S` | Screenshot Menu |
| `Super + .` | Emoji Picker |

---

<div align="center">
  <sub><strong>CelestialShade</strong> forged </sub>
</div>

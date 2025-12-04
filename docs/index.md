---
layout: home

hero:
  name: "Celestial Shade"
  text: "A Self Contained Lua-driven Hyprland Ecosystem"
  tagline: "Minimal and Cozy by default. Powerful when needed."
  image:
    src: <img width="744" height="744" alt="hero" src="https://github.com/user-attachments/assets/1135734b-75f3-447b-831b-a497af23c8d2" />
    alt: Celestial Shade Desktop
  actions:
    - theme: brand
      text: Install Now
      link: /guide/installation
    - theme: alt
      text: Explore Theming
      link: /guide/theming

features:
  - title: 🔮 Lua Compiler Engine
    details: No messy bash scripts. A central Lua engine compiles palettes into valid configs for Hyprland, Rofi, and Waybar instantly.
    icon: 🧠
  
  - title: 🏝️ Dynamic Islands
    details: A reactive Waybar configuration with expanding drawers for Screenshots, Power, and Dashboards.
    icon: 🏝️

  - title: 🧠 State Awareness
    details: The wallpaper engine has memory. It remembers exactly which image you were using for <i>each</i> specific theme.
    icon: 💾

  - title: 🎨 8 Universal Themes
    details: Switch instantly between Catppuccin, Rose Pine, Everforest, Synthwave, and more with a single keystroke.
    icon: 🎨

  - title: ⚡ Native Artifacts
    details: Generates valid CSS, .conf, and .rasi files on the fly. Zero reliance on heavy daemons.
    icon: ⚡

  - title: 🛠️ Integrated Utilities
    details: Includes custom tools for Clipboard management, Emoji picking (1900+ glyphs), and System Diagnostics.
    icon: 🧰
---

<style>
:root {
  /* Catppuccin Mocha-inspired overrides for the landing page */
  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: -webkit-linear-gradient(120deg, #cba6f7 30%, #89b4fa);
  --vp-home-hero-image-background-image: linear-gradient(-45deg, #cba6f7 50%, #89b4fa 50%);
  --vp-home-hero-image-filter: blur(40px);
}
</style>

## Why Celestial Shade?

Most Hyprland configurations rely on a web of fragile Bash scripts and `sed` commands to change colors.

**Celestial Shade is different.** 

It treats your configuration as **Software**. 
1.  **Data:** Themes are pure Lua tables.
2.  **Logic:** The Engine reads the data.
3.  **Output:** The Engine writes strict, valid configuration files ("Artifacts") for every app.

This ensures 100% consistency across your entire desktop, with zero breakage.

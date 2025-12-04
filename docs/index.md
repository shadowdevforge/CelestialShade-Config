---
layout: home

hero:
  name: "Celestial Shade"
  text: "A Self Contained Lua-driven Hyprland Ecosystem"
  tagline: "Minimal and Cozy by default. Powerful when needed."
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

## Why Celestial Shade?

Most Hyprland configurations rely on a web of fragile Bash scripts and `sed` commands to change colors.

**Celestial Shade is different.** 

It treats your configuration as **Software**. 
1.  **Data:** Themes are pure Lua tables.
2.  **Logic:** The Engine reads the data.
3.  **Output:** The Engine writes strict, valid configuration files ("Artifacts") for every app.

This ensures 100% consistency across your entire desktop, with zero breakage.

<style>
:root {
  /* Catppuccin Palette */
  --c-mauve: #cba6f7;
  --c-blue: #89b4fa;
  --c-pink: #f5c2e7;
  --c-base: #1e1e2e;
  --c-surface: #313244;
}

/* 1. THE CELESTIAL GLOW (Background Animation) */
.VPHero {
  position: relative;
  overflow: hidden;
}

.VPHero::before {
  content: '';
  position: absolute;
  top: -150px;
  left: 50%;
  transform: translateX(-50%);
  width: 600px;
  height: 600px;
  background: radial-gradient(circle, 
    rgba(203, 166, 247, 0.5) 0%, 
    rgba(137, 180, 250, 0.3) 40%, 
    transparent 70%
  );
  filter: blur(90px);
  z-index: -1;
  animation: celestial-pulse 8s ease-in-out infinite alternate;
}

@keyframes celestial-pulse {
  0% { transform: translateX(-50%) scale(1); opacity: 0.6; }
  100% { transform: translateX(-50%) scale(1.3); opacity: 0.9; }
}

/* 2. GRADIENT TEXT FOR TITLE */
.VPHero .name {
  background: -webkit-linear-gradient(315deg, var(--c-mauve) 25%, var(--c-blue));
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  filter: drop-shadow(0 0 20px rgba(203, 166, 247, 0.4));
}

/* 3. GLASSMORPHISM CARDS */
.VPFeature {
  background-color: rgba(30, 30, 46, 0.6) !important;
  border: 1px solid rgba(203, 166, 247, 0.1) !important;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
  border-radius: 16px !important;
}

.VPFeature:hover {
  transform: translateY(-5px);
  border-color: var(--c-mauve) !important;
  box-shadow: 0 10px 30px -10px rgba(203, 166, 247, 0.3);
  background-color: rgba(30, 30, 46, 0.8) !important;
}

/* 4. BUTTON GLOW */
.VPButton.brand {
  background-color: var(--c-mauve) !important;
  color: var(--c-base) !important;
  box-shadow: 0 0 20px rgba(203, 166, 247, 0.5);
  transition: all 0.3s ease;
  border: none;
}

.VPButton.brand:hover {
  background-color: var(--c-pink) !important;
  box-shadow: 0 0 30px rgba(245, 194, 231, 0.7);
}

/* 5. ICON BACKGROUNDS */
.VPFeature .icon {
  background-color: rgba(137, 180, 250, 0.1) !important;
  border-radius: 8px;
}
</style>

import { defineConfig } from 'vitepress'

export default defineConfig({
  // CRITICAL: Matches your repo name for GitHub Pages
  base: '/CelestialShade-Config/', 

  title: "Celestial Shade",
  description: "A Lua-driven, modular Hyprland ecosystem.",
  
  cleanUrls: true,
  lastUpdated: true,

  // 1. Re-added Favicon support
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }]
  ],

  themeConfig: {
    // 2. Re-added Logo (ensure logo.png is in docs/public/)
    // If you don't have a logo file yet, you can comment this out.
    // logo: '/logo.png', 
    
    siteTitle: 'Celestial Shade',
    
    search: {
      provider: 'local'
    },

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Installation', link: '/guide/installation' },
      { text: 'The Engine', link: '/guide/engine' },
      { text: 'GitHub', link: 'https://github.com/shadowdevforge/CelestialShade-Config' }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Installation', link: '/guide/installation' },
          // 3. Re-added System Doctor (It's a key feature!)
          { text: 'System Doctor', link: '/guide/doctor' } 
        ]
      },
      {
        text: 'Core Architecture',
        collapsed: false,
        items: [
          { text: 'The Lua Engine', link: '/guide/engine' },
        ]
      },
      {
        text: 'Customization',
        collapsed: false,
        items: [
          { text: 'Theming & Wallpapers', link: '/guide/theming' },
          { text: 'Keybindings', link: '/guide/keybindings' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/shadowdevforge/CelestialShade-Config' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025-present shadowdevforge'
    },

    editLink: {
      pattern: 'https://github.com/shadowdevforge/CelestialShade-Config/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    }
  }
})

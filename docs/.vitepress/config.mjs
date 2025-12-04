import { defineConfig } from 'vitepress'

export default defineConfig({
  // CRITICAL: Matches your repo name for GitHub Pages
  base: '/CelestialShade-Config/', 

  title: "Celestial Shade",
  description: "A Lua-driven, modular Hyprland ecosystem.",
  
  cleanUrls: true,
  lastUpdated: true,

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }]
  ],

  themeConfig: {
    logo: '/logo.png',
    siteTitle: 'Celestial Shade',

    // Search
    search: {
      provider: 'local'
    },

    // Top Navigation
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Installation', link: '/guide/installation' },
      { text: 'The Engine', link: '/guide/engine' },
      { text: 'GitHub', link: 'https://github.com/shadowdevforge/CelestialShade-Config' }
    ],

    // Sidebar Navigation
    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Installation', link: '/guide/installation' },
          { text: 'System Doctor', link: '/guide/doctor' }
        ]
      },
      {
        text: 'Core Architecture',
        collapsed: false,
        items: [
          { text: 'The Lua Engine', link: '/guide/engine' },
          { text: 'Project Structure', link: '/guide/structure' } // Make sure this file exists or remove line
        ]
      },
      {
        text: 'Customization',
        collapsed: false,
        items: [
          { text: 'Theming & Wallpapers', link: '/guide/theming' },
          { text: 'Keybindings', link: '/guide/keybindings' },
          { text: 'Waybar Islands', link: '/guide/waybar' } // Make sure this file exists or remove line
        ]
      }
    ],

    // Social Links
    socialLinks: [
      { icon: 'github', link: 'https://github.com/shadowdevforge/CelestialShade-Config' }
    ],

    // Footer
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025-present shadowdevforge'
    },

    // Edit Link
    editLink: {
      pattern: 'https://github.com/shadowdevforge/CelestialShade-Config/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    }
  }
})

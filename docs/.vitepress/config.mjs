import { defineConfig } from 'vitepress'

export default defineConfig({
  base: '/CelestialShade-Config/', 
  
  title: "Celestial Shade",
  export default defineConfig({
  title: "Celestial Shade",
  description: "A Lua-driven, modular Hyprland ecosystem.",
  
  // Removes .html from URLs for a cleaner look
  cleanUrls: true,
  lastUpdated: true,

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    // Font setup (optional, if you want to force JetBrains Mono on the site)
    ['link', { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap' }]
  ],

  themeConfig: {
    // Logo in top left
    logo: '/logo.png', // Make sure to add a logo to public/logo.png
    siteTitle: 'Celestial Shade',

    // Top Navigation
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Installation', link: '/guide/installation' },
      { text: 'The Engine', link: '/guide/engine' },
      { text: 'GitHub', link: 'https://github.com/shadowdevforge/CelestialShade-Config' }
    ],

    // Sidebar Navigation (The important part)
    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Introduction', link: '/guide/intro' }, // Optional intro page
          { text: 'Installation', link: '/guide/installation' },
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
        ]
      }
    ],

    // Social Icons
    socialLinks: [
      { icon: 'github', link: 'https://github.com/shadowdevforge/CelestialShade-Config' },
    ],

    // Built-in Search
    search: {
      provider: 'local'
    },

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

import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'CheckRef',
  description: 'Allele Switch Checker for Population Genetics',
  base: '/checkref/',
  lang: 'en-US',

  themeConfig: {
    logo: '/logo.png',

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Tutorials', link: '/tutorials/' },
      { text: 'Examples', link: '/examples/' },
      { text: 'Parameters', link: '/api/parameters' },
      { text: 'Workflow', link: '/workflow/' }
    ],

    sidebar: {
      '/tutorials/': [
        {
          text: 'Tutorials',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/tutorials/' },
            { text: 'Quick Start', link: '/tutorials/quick-start' }
          ]
        }
      ],
      '/guide/': [
        {
          text: 'Getting Started',
          collapsed: false,
          items: [
            { text: 'Introduction', link: '/guide/getting-started' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quick-start' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        },
        {
          text: 'Pipeline Usage',
          collapsed: false,
          items: [
            { text: 'Input Files', link: '/guide/input-files' },
            { text: 'Running the Pipeline', link: '/guide/running' },
            { text: 'Output Files', link: '/guide/output-files' },
            { text: 'Troubleshooting', link: '/guide/troubleshooting' }
          ]
        }
      ],
      '/api/': [
        {
          text: 'Reference',
          collapsed: false,
          items: [
            { text: 'Parameters', link: '/api/parameters' },
            { text: 'Profiles', link: '/api/profiles' },
            { text: 'Modules', link: '/api/modules' }
          ]
        }
      ],
      '/workflow/': [
        {
          text: 'Workflow Details',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/workflow/' },
            { text: 'Process Flow', link: '/workflow/process-flow' },
            { text: 'Subworkflows', link: '/workflow/subworkflows' },
            { text: 'Resource Usage', link: '/workflow/resources' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/AfriGen-D/checkref' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 AfriGen-D Project'
    },

    search: {
      provider: 'local'
    }
  },

  markdown: {
    lineNumbers: true,
    math: true
  }
})
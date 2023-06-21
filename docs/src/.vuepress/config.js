const { description } = require('../../package')
const ddoc_link = require('../ddoc-link')

module.exports = {
  /**
   * Ref：https://v1.vuepress.vuejs.org/config/#title
   */
  title: 'SLF4D Documentation',
  /**
   * Ref：https://v1.vuepress.vuejs.org/config/#description
   */
  description: description,

  base: '/slf4d/',

  /**
   * Extra tags to be injected to the page HTML `<head>`
   *
   * ref：https://v1.vuepress.vuejs.org/config/#head
   */
  head: [
    ['meta', { name: 'theme-color', content: '#3eaf7c' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }]
  ],

  /**
   * Theme configuration, here is the default theme configuration for VuePress.
   *
   * ref：https://v1.vuepress.vuejs.org/theme/default-theme-config.html
   */
  themeConfig: {
    repo: '',
    editLinks: false,
    docsDir: '',
    editLinkText: '',
    lastUpdated: false,
    nav: [
      {
        text: 'Guide',
        link: '/guide/',
      },
      {
        text: 'GitHub',
        link: 'https://github.com/andrewlalis/slf4d'
      },
      {
        text: 'code.dlang.org',
        link: 'https://code.dlang.org/packages/slf4d'
      },
      {
        text: 'ddoc',
        link: '/slf4d/ddoc/index.html',
        target: '_blank'
      }
    ],
    sidebar: {
      '/guide/': [
        {
          title: 'Basics',
          collapsable: false,
          children: [
            '',
            'using-slf4d',
            'configuring',
            'testing',
            'default-provider',
          ]
        }
      ],
    }
  },

  /**
   * Apply plugins，ref：https://v1.vuepress.vuejs.org/zh/plugin/
   */
  plugins: [
    '@vuepress/plugin-back-to-top',
    '@vuepress/plugin-medium-zoom',
    // ['vuepress-plugin-code-copy', {
    //   backgroundTransition: false,
    //   staticIcon: false,
    //   color: '#ff3900',
    //   successText: 'Copied to clipboard.'
    // }],
    [ddoc_link({
      version: '5.0.0',
      moduleName: 'handy-httpd'
    })]
  ]
}

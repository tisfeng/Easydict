import { defineConfig } from 'vitepress'
import zh from './zh.mjs'

const en = defineConfig({
  description: "Easy to look up words or translate text",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/installation', activeMatch: '/guide/' }
    ],

    sidebar: {
      '/guide/': {
        base: '/guide/',
        items: [
          {
            text: 'Usage',
            items: [
              { text: 'Installation', link: 'installation' },
              { text: 'Selected Translate', link: 'selected-translate' },
              { text: 'OCR', link: 'ocr' },
              { text: 'TTS', link: 'tts' },
              { text: 'Services', link: 'services' },
              { text: 'How-to-use-macOS-system-dictionary', link: 'How-to-use-macOS-system-dictionary'},
              { text: 'How-to-use-macOS-system-translation', link: 'How-to-use-macOS-system-translation'},
            ]
          }, {
            text: 'Features',
            items: [
              { text: 'FeatureA', link: 'ocr' },
              { text: 'FeatureB', link: 'ocr' },
            ]
          }
        ]
      },
    },

    editLink: {
      pattern: 'https://github.com/yangg/easydictdoc/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },
  }
})

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Easydict",
  locales: {
    root: { label: 'English', ...en },
    zh: { label: '简体中文', ...zh }
  },
})

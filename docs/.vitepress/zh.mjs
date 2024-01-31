import {defineConfig} from "vitepress";

const langConfig = defineConfig({
  lang: 'zh-Hans',
  description: "Easy to look up words or translate text",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/zh/' },
      { text: 'Guide', link: '/zh/guide/installation' }
    ],

    sidebar: {
      '/zh/guide/': { base: '/zh/guide/', items: [
          { text: 'Installation', link: 'installation' },
          { text: 'Selected Translate', link: 'selected-translate' },
          { text: 'OCR', link: 'ocr' },
          { text: 'TTS', link: 'tts' },
          { text: 'Services', link: 'services  ' },
          { text: 'How-to-use-macOS-system-dictionary', link: 'How-to-use-macOS-system-dictionary'},
          { text: 'How-to-use-macOS-system-translation', link: 'How-to-use-macOS-system-translation'},
        ] },
    },

    editLink: {
      pattern: 'https://github.com/yangg/easydictdoc/edit/main/docs/:path',
      text: '在 GitHub 上编辑此页面'
    },
  }
})

export default langConfig

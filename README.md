<p align="center">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/icon_512x512@2x.png" height="256">
  <h1 align="center">Easydict</h1>
  <h4 align="center"> Easy to look up words or translate text</h4>
<p align="center"> 
<a href="https://github.com/tisfeng/easydict/blob/main/LICENSE">
<img src="https://img.shields.io/github/license/tisfeng/easydict"
            alt="License"></a>
<a href="https://github.com/tisfeng/Easydict/releases">
<img src="https://img.shields.io/github/downloads/tisfeng/easydict/total.svg"
            alt="Downloads"></a>
<a href="https://img.shields.io/badge/-macOS-black?&logo=apple&logoColor=white">
<img src="https://img.shields.io/badge/-macOS-black?&logo=apple&logoColor=white"
            alt="macOS"></a>  
</p>

<div align="center">
<a href="./README.md">中文</a> &nbsp;&nbsp;|&nbsp;&nbsp; <a href="./README_EN.md">English</a>
</div>

## Easydict

`Easydict` 是一个简洁易用的词典翻译 macOS App，能够轻松优雅地查找单词或翻译文本。Easydict 开箱即用，能自动识别输入文本语言，支持输入翻译，划词翻译和 OCR 截图翻译，可同时查询多个翻译服务结果，目前支持 [**🍎 苹果系统词典**](./docs/zh/How-to-use-macOS-system-dictionary-in-Easydict.md)，[🍎 **苹果系统翻译**](./docs/zh/How-to-use-macOS-system-translation-in-Easydict.md)，[OpenAI](https://chat.openai.com/)，[Gemini](https://gemini.google.com/)，[DeepSeek](https://www.deepseek.com/)，[Ollama](https://ollama.com/)，[Groq](https://groq.com/)，[智谱AI](https://open.bigmodel.cn/)，[GitHub Models](https://github.com/marketplace/models)，[DeepL](https://www.deepl.com/translator)，[Google](https://translate.google.com)，[有道词典](https://www.youdao.com/)，[腾讯](https://fanyi.qq.com/)，[Bing](https://www.bing.com/translator)，[百度](https://fanyi.baidu.com/)，[小牛翻译](https://niutrans.com/)，[彩云小译](https://fanyi.caiyunapp.com/)，[阿里翻译](https://translate.alibaba.com/)，[火山翻译](https://translate.volcengine.com/translate) 和 [豆包翻译](https://www.volcengine.com/docs/82379/1820188)。

![Log](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Log-1688378715.png)

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.18-1685262784.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.26-1685262803.png">
</table>

![immerse-1686534718.gif](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/immerse-1686534718.gif)

## 功能特性

- 🚀 开箱即用，自动识别输入语言
- 🖱️ 鼠标自动划词和快捷键划词
- 📸 OCR 截图翻译，静默截图 OCR
- 🔊 多种 TTS 语音服务
- 📚 支持 🍎 [苹果系统词典](./docs/zh/How-to-use-macOS-system-dictionary-in-Easydict.md) 和 [系统翻译](./docs/zh/How-to-use-macOS-system-translation-in-Easydict.md)
- 🌐 支持 20+ 翻译服务（OpenAI、Gemini、DeepL、Google、Ollama、Groq 等）
- 🗣️ 支持 48 种语言

**如果觉得这个应用还不错，给个 [Star](https://github.com/tisfeng/Easydict) ⭐️ 支持一下吧 (^-^)**

## 安装

### Homebrew 安装（推荐）

```bash
brew install --cask easydict
```

### 手动下载安装

[下载](https://github.com/tisfeng/Easydict/releases) 最新版本的 Easydict。

> 最新版本支持 macOS 13.0+，如果系统版本为 macOS 11.0+，请使用 [2.7.2](https://github.com/tisfeng/Easydict/releases/tag/2.7.2)

---

## 文档

- 📖 [完整使用指南](./docs/zh/GUIDE.md) - 详细功能说明和配置方法
- 🔧 [开发者构建指南](./docs/zh/GUIDE.md#开发者构建) - 从源码编译运行
- 🍎 [如何使用 macOS 系统词典](./docs/zh/How-to-use-macOS-system-dictionary-in-Easydict.md)
- 🍎 [如何使用 macOS 系统翻译](./docs/zh/How-to-use-macOS-system-translation-in-Easydict.md)
- 🌍 [如何帮助翻译 Easydict](./docs/How-to-translate-Easydict-zh.md)

---

## Star History

<a href="https://star-history.com/#tisfeng/easydict&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=tisfeng/easydict&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=tisfeng/easydict&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=tisfeng/easydict&type=Date" />
  </picture>
</a>

## 致谢

- 这个项目的灵感来自 [saladict](https://github.com/crimx/ext-saladict) 和 [Bob](https://github.com/ripperhe/Bob)，且初始版本是以 [Bob (GPL-3.0)](https://github.com/1xiaocainiao/Bob) 为基础开发。Easydict 在原项目上进行了许多改进和优化，很多功能和 UI 都参考了 Bob。
- 截图功能是基于 [isee15](https://github.com/isee15) 的 [Capture-Screen-For-Multi-Screens-On-Mac](https://github.com/isee15/Capture-Screen-For-Multi-Screens-On-Mac)，并在此基础上进行了优化。
- 鼠标划词功能参考了 [PopClip](https://pilotmoon.com/popclip/)。

## 声明

Easydict 为 [GPL-3.0](https://github.com/tisfeng/Easydict/blob/main/LICENSE) 开源协议，仅供学习交流，任何人都可以免费获取该产品和源代码。如果你认为您的合法权益受到侵犯，请立即联系[作者](https://github.com/tisfeng)。你可以自由使用源代码，但必须附上相应的许可证和版权声明。

## 赞助支持

Easydict 作为一个免费开源的非盈利项目，目前主要是作者个人在开发和维护，如果你喜欢这个项目，觉得它对你有帮助，可以考虑赞助支持一下这个项目，用爱发电，让它能够走得更远。

<a href="https://afdian.com/a/tisfeng"><img width="20%" src="https://pic1.afdiancdn.com/static/img/welcome/button-sponsorme.jpg" alt=""></a>

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/IMG_4739-1684680971.JPG" width="30%">
</div>

感谢所有支持者的赞助，详情请看查看 [赞助列表](./docs/zh/SPONSOR_LIST.md)。


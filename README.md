<p align="center">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/icon_512x512-1671278252.png" height="256">
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

`Easydict` 是一个简洁易用的词典翻译 macOS App，能够轻松优雅地查找单词或翻译文本。Easydict 开箱即用，能自动识别输入文本语言，支持输入翻译，划词翻译和 OCR 截图翻译，可同时查询多个翻译服务结果，目前支持 [有道词典](https://www.youdao.com/)，[**🍎 苹果系统词典**](./docs/How-to-use-macOS-system-dictionary-in-Easydict-zh.md)，[🍎 **苹果系统翻译**](./docs/How-to-use-macOS-system-translation-in-Easydict-zh.md)，[OpenAI](https://chat.openai.com/)，[Gemini](https://gemini.google.com/)，[DeepL](https://www.deepl.com/translator)，[Google](https://translate.google.com)，[腾讯](https://fanyi.qq.com/)，[Bing](https://www.bing.com/translator)，[百度](https://fanyi.baidu.com/)，[小牛翻译](https://niutrans.com/)，[彩云小译](https://fanyi.caiyunapp.com/)，[阿里翻译](https://translate.alibaba.com/) 和 [火山翻译](https://translate.volcengine.com/translate)。

![Log](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Log-1688378715.png)

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.18-1685262784.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.26-1685262803.png">
</table>

![immerse-1686534718.gif](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/immerse-1686534718.gif)

## 功能

- [x] 开箱即用，便捷查询单词或翻译文本。
- [x] 自动识别输入语言，自动查询目标偏好语言。
- [x] 自动划词查询，划词后自动显示查询图标，鼠标悬浮即可查询。
- [x] 支持为不同窗口配置不同的服务。
- [x] 支持智能查询模式。
- [x] 支持系统 OCR 截图翻译，静默截图 OCR。
- [x] 支持系统 TTS，支持 Bing，Google，有道和百度在线 TTS 服务。
- [x] 支持 [🍎 苹果系统词典](./docs/How-to-use-macOS-system-dictionary-in-Easydict-zh.md)，支持第三方词典，可手动导入 mdict 词典。
- [x] 支持 macOS 系统翻译。详情请看 [如何在 Easydict 中使用 🍎 macOS 系统翻译？](./docs/How-to-use-macOS-system-translation-in-Easydict-zh.md)
- [x] 支持有道词典，OpenAI，Gemini，DeepL，Google，Bing，腾讯，百度，小牛，彩云，阿里和火山翻译。
- [x] 支持 48 种语言。

**如果觉得这个应用还不错，给个 [Star](https://github.com/tisfeng/Easydict) ⭐️ 支持一下吧 (^-^)**

## Swift 重构计划

我们计划用 Swift 重构项目，如果你对这个开源项目感兴趣，熟悉 Swift/SwiftUI，欢迎加入我们的开发组，一起完善这个项目 [#194](https://github.com/tisfeng/Easydict/issues/194)。

---

## 目录

- [Easydict](#easydict)
- [功能](#功能)
- [Swift 重构计划](#swift-重构计划)
- [目录](#目录)
- [安装](#安装)
  - [1. 手动下载安装](#1-手动下载安装)
  - [2. Homebrew 安装](#2-homebrew-安装)
  - [开发者构建](#开发者构建)
    - [构建环境](#构建环境)
- [使用](#使用)
  - [鼠标划词](#鼠标划词)
  - [关于权限](#关于权限)
- [OCR](#ocr)
- [语种识别](#语种识别)
- [TTS 服务](#tts-服务)
- [查询服务](#查询服务)
  - [  各个服务支持的语言 ](#--各个服务支持的语言-)
  - [🍎 苹果系统词典](#-苹果系统词典)
  - [OpenAI 翻译](#openai-翻译)
    - [使用内置 APIKey](#使用内置-apikey)
    - [配置个人的 APIKey](#配置个人的-apikey)
    - [OpenAI 查询模式](#openai-查询模式)
    - [OpenAI 自定义参数](#openai-自定义参数)
  - [Gemini 翻译](#gemini-翻译)
  - [DeepL 翻译](#deepl-翻译)
    - [配置 AuthKey](#配置-authkey)
    - [自定义 DeepL 接口地址](#自定义-deepl-接口地址)
    - [配置 API 调用方式](#配置-api-调用方式)
  - [腾讯翻译](#腾讯翻译)
  - [Bing 翻译](#bing-翻译)
  - [小牛翻译](#小牛翻译)
  - [彩云小译](#彩云小译)
  - [阿里翻译](#阿里翻译)
- [智能查询模式](#智能查询模式)
  - [应用内查询](#应用内查询)
- [URL Scheme](#url-scheme)
- [配合 PopClip 使用](#配合-popclip-使用)
- [设置](#设置)
  - [通用](#通用)
  - [服务](#服务)
- [应用内快捷键](#应用内快捷键)
- [Tips](#tips)
- [类似开源项目](#类似开源项目)
- [初衷](#初衷)
- [贡献指南](#贡献指南)
- [Star History](#star-history)
- [致谢](#致谢)
- [声明](#声明)
- [赞助支持](#赞助支持)
  - [赞助列表](#赞助列表)

## 安装

你可以使用下面两种方式之一安装。支持系统 macOS 11.0+

### 1. 手动下载安装

[下载](https://github.com/tisfeng/Easydict/releases) 最新版本的 Easydict。

### 2. Homebrew 安装

感谢 [BingoKingo](https://github.com/tisfeng/Easydict/issues/1#issuecomment-1445286763) 提供的最初安装版本。

```bash
brew install --cask easydict
```

### 开发者构建

如果你是一名开发者，或者对这个项目感兴趣，也可以尝试手动构建运行，整个过程非常简单，甚至不需懂 macOS 开发知识。

<details> <summary> 构建步骤 </summary>

<p>

1. 下载这个 Repo，然后使用 [Xcode](https://developer.apple.com/xcode/) 打开 `Easydict.xcworkspace` 文件（⚠️⚠️⚠️ 注意不是 `Easydict.xcodeproj` ⚠️⚠️⚠️）。
2. 使用 `Cmd + R` 编译运行即可。

![image-20231212125308372](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231212125308372-1702356789.png)

以下是可选步骤，仅面向开发协作者。

如果经常需要调试一些权限相关的功能，例如取词或 OCR，可选择使用自己的苹果账号运行，请修改 `Easydict-debug.xcconfig` 文件中的 `DEVELOPMENT_TEAM` 为你自己的 Apple Team ID（你可以登录苹果开发者网站找到它），`CODE_SIGN_IDENTITY` 改为 Apple Development。

注意不要提交 `Easydict-debug.xcconfig` 文件，你可以使用下面 git 命令忽略这个文件的本地修改

```bash
git update-index --skip-worktree Easydict-debug.xcconfig
```

#### 构建环境

Xcode 13+, macOS Big Sur 11.3+。为避免不必要的问题，建议使用最新的 Xcode 和 macOS 版本 https://github.com/tisfeng/Easydict/issues/79

>[!NOTE]
> 由于最新代码使用了 String Catalog 功能，因此需要 Xcode 15+ 才能编译。
> 如果你的 Xcode 版本较低，请使用 [xcode-14](https://github.com/tisfeng/Easydict/tree/xcode-14) 分支，注意这是一个固定版本分支，不受维护。

如果运行遇到下面错误，请尝试升级 CocoaPods 到最新版本，然后执行 `pod install`。

>  [DT_TOOLCHAIN_DIR cannot be used to evaluate LD_RUNPATH_SEARCH_PATHS, use TOOLCHAIN_DIR instead](https://github.com/CocoaPods/CocoaPods/issues/12012)

</p>

</details>

---

## 使用

Easydict 启动之后，除了应用主界面（默认隐藏），还会有一个菜单图标，点击菜单选项即可触发相应的功能，如下所示：

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/xb77fI-1684688321.png" width="50%" />
</div>

| 方式           | 描述                                                                                         | 预览                                                                                                                                           |
| -------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| 鼠标划词翻译   | 划词后自动显示查询图标，鼠标悬浮即可查询                                                     | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| 快捷键划词翻译 | 选中需要翻译的文本之后，按下划词翻译快捷键即可（默认 `⌥ + D`）                               | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| 截图翻译       | 按下截图翻译快捷键（默认 `⌥ + S`），截取需要翻译的区域                                       | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| 输入翻译       | 按下输入翻译快捷键（默认 `⌥ + A` 或 `⌥ + F`），输入需要翻译的文本，`Enter` 键翻译            | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |
| 静默截图 OCR   | 按下静默截图快捷键（默认 `⌥ + ⇧ + S`），截取需要 OCR 的区域，截图 OCR 结果将自动保存到剪贴板 | ![屏幕录制 2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                    |
|                |

### 鼠标划词

目前支持多种鼠标快捷划词方式：双击划词、鼠标滑动划词、三击划词（段落）和 Shift 划词（多段落），在某些应用中【鼠标滑动划词】可能会失败，此时可换其他划词方式。

快捷键划词在任意应用中都可以正常工作。如遇到不能鼠标划词的应用，可提 issue 解决 https://github.com/tisfeng/Easydict/issues/84

划词功能流程：Accessibility > AppleScript > 模拟快捷键，优先使用辅助功能 Accessibility 取词，在 Accessibility 取词失败（未授权或应用不支持）时，如果是浏览器应用（如 Safari, Chrome），会尝试使用 AppleScript 取词。若 AppleScript 取词还是失败，最后则进行强制取词——模拟快捷键 Cmd+C 取词。

因此，建议开启浏览器中的 `允许 Apple 事件中的 JavaScript` 选项，这样可以避免某些网页的事件拦截，例如这种 [网页强制附带版权信息](https://github.com/tisfeng/Easydict/issues/85) 问题，优化取词体验。

对于 Safari 用户，强烈建议开启该选项，因为 Safari 不支持 Accessibility 取词，而 AppleScript 取词体验远优于模拟快捷键取词。

<div>
    <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230708115811617-1688788691.png" width="45%">
    <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230708115827839-1688788707.png" width="45%">
</div>

### 关于权限

1. 划词翻译，需要开启 `辅助功能` 权限，鼠标划词功能仅在第一次使用时会触发申请辅助功能权限，授权后才能正常使用自动划词翻译功能。

2. 截图翻译，需要开启 `屏幕录制` 权限，应用仅会在第一次使用 **截图翻译** 时会自动弹出权限申请对话框，若授权失败，后续需自己去系统设置中开启。

## OCR

目前仅支持系统 OCR，稍后会引入第三方 OCR 服务。

系统 OCR 支持语言：简体中文，繁体中文，英语，日语，韩语，法语，西班牙语，葡萄牙语，德语，意大利语，俄语，乌克兰语。

## 语种识别

目前支持系统语种识别，百度和 Google 语种识别三种，但考虑到在线识别的速度问题以及不稳定性（Google 还需要翻墙），其他两种识别服务只用于辅助优化。

默认使用系统语种识别，经调教后，系统语种识别的准确率已经很高了，能够满足大部分用户的需求。

如果在实际使用中还是觉得系统语种识别不准确，可在设置中开启百度语种识别或 Google 语种识别优化，但请注意，这可能会导致响应速度变慢，而且识别率也不会 100% 符合用户期望。如遇到识别有误情况，建议手动指定语种类型。

## TTS 服务

目前支持系统 TTS，支持 Bing，Google，有道和百度在线 TTS 服务。

- 系统 TTS：最稳定可靠，但效果不是很好。通常作为备用选项，即使用其他 TTS 报错时会改用系统 TTS。
- Bing TTS：综合效果最好，实时合成神经网络语音，但比较耗时，且文本越长，合成时间越长，目前限制最多只能合成 2000 个字符，约 10 分钟。
- Google TTS：英文效果不错，接口稳定，但需要翻墙，且一次请求最多只能合成 200 个字符。
- 有道 TTS：整体效果不错，接口稳定，尤其英语单词发音极好，但最多只能合成 600 个字符。
- 百度 TTS：英文句子发音很好，口音很有特色，但最多只能合成约 1000 个字符。

默认使用有道 TTS，用户可在设置中切换偏好 TTS 服务。

鉴于有道 TTS 的英语单词效果很好，因此英文单词优先使用有道 TTS，其他文本则使用默认 TTS 服务。

除系统 TTS 外，其他 TTS 服务都是非官方接口，可能不稳定。

## 查询服务

目前支持有道词典，苹果系统词典，苹果系统翻译，DeepL，Google，Bing，百度和火山翻译。

> [!NOTE]
> Google 翻译中国版已无法使用，只能使用国际版，因此需要走代理才能使用 Google 翻译。

### <details> <summary> 各个服务支持的语言 </summary>

<p>

|     语言     | 有道词典 | 🍎 苹果系统翻译 | DeepL 翻译 | Bing 翻译 | Google 翻译 | 百度翻译 | 火山翻译 |
| :----------: | :------: | :---------: | :--------: | :------: | :---------: | :------: | :------: |
| 中文（简体） |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
| 中文（繁体） |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     英语     |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     日语     |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     韩语     |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     法语     |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   西班牙语   |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   葡萄牙语   |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   意大利语   |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     德语     |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     俄语     |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   阿拉伯语   |    ✅    |     ✅      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|    瑞典语    |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|  罗马尼亚语  |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|     泰语     |    ✅    |     ✅      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|  斯洛伐克语  |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    荷兰语    |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   匈牙利语   |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    希腊语    |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    丹麦语    |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    芬兰语    |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    波兰语    |    ❌    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    捷克语    |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   土耳其语   |    ❌    |     ✅      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   立陶宛语   |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|  拉脱维亚语  |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|   乌克兰语   |    ❌    |     ✅     |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|  保加利亚语  |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    印尼语    |    ✅    |     ✅      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    马来语    |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
| 斯洛文尼亚语 |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|  爱沙尼亚语  |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|    越南语    |    ✅    |     ✅      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|    波斯语    |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|    印地语    |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   泰卢固语   |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   泰米尔语   |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   乌尔都语   |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   菲律宾语   |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|    高棉语    |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|    老挝语    |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   孟加拉语   |    ❌    |     ❌      |     ❌     |    ❌    |     ✅      |    ✅    |    ✅    |
|    缅甸语    |    ❌    |     ❌      |     ❌     |    ❌    |     ✅      |    ✅    |    ✅    |
|    挪威语    |    ❌    |     ❌      |     ✅     |    ✅    |     ✅      |    ✅    |    ✅    |
|  塞尔维亚语  |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|  克罗地亚语  |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|    蒙古语    |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |
|   希伯来语   |    ❌    |     ❌      |     ❌     |    ✅    |     ✅      |    ✅    |    ✅    |

</p>

</details>

### 🍎 苹果系统词典

Easydict 自动支持词典 App 中系统自带的词典，如牛津英汉汉英词典（简体中文-英语），现代汉语规范词典（简体中文）等，只需在词典 App 设置页启用相应的词典即可。

另外，苹果词典也支持自定义导入词典，因此我们可以通过导入 .dictionary 格式的词典来添加第三方词典，如简明英汉字典，朗文当代高级英语辞典等。

详情请看 [如何在 Easydict 中使用 🍎 macOS 系统词典？](./docs/How-to-use-macOS-system-dictionary-in-Easydict-zh.md)

<table>
 		<td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HModYw-1696150530.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
</table>

### OpenAI 翻译

1.3.0 版本开始支持 OpenAI 翻译，也支持 Azure OpenAI 接口，需要使用 OpenAI API key。

如果你没有自己的 OpenAI APIKey，可以借助一些开源项目将第三方的 LLM 接口转为标准的 OpenAI 接口，这样就能直接在 `Easydict` 中使用了。

例如 [one-api](https://github.com/songquanpeng/one-api)，one-api 是一个很好的 OpenAI 接口管理开源项目，支持多家 LLM 接口，包括 Azure、Anthropic Claude、Google PaLM 2 & Gemini、智谱 ChatGLM、百度文心一言、讯飞星火认知、阿里通义千问、360 智脑以及腾讯混元等，可用于二次分发管理 key，仅单可执行文件，已打包好 Docker 镜像，一键部署，开箱即用。

**[2.6.0](https://github.com/tisfeng/Easydict/releases) 版本实现了新的 SwiftUI 设置页（支持 macOS 13+），支持 GUI 方式配置服务 API key，其他系统版本则需要在 Easydict 的输入框中使用命令方式配置。**

> [!NOTE]
> 如果电脑硬件支持的话，建议升级到最新的 macOS 系统，以享受更好的用户体验。

![](https://github.com/tisfeng/Easydict/assets/25194972/5b8f2785-b0ee-4a9e-bd41-1a9dd56b0231)

#### 使用内置 APIKey

目前 Google 的 Gemini API 免费，实测下来翻译效果不错，为方便用户使用，我内置了一个 key。但请注意，这个 key 有一定使用限制且不稳定，因此如果有能力部署 one-api，建议优先使用自己的 APIKey。

在 Beta 模式下，并且没有设置自己的 APIKey，这样就会自动使用内置的 Gemini key。

写入以下命令可开启 Beta 模式

```bash
easydict://writeKeyValue?EZBetaFeatureKey=1
```

#### 配置个人的 APIKey

```bash
easydict://writeKeyValue?EZOpenAIAPIKey=sk-xxx
```

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231104131750966-1699075071.png" width="50%" />
</div>

查看 APIKey (其他 key 类似)，如果查询成功，会将结果写到剪贴板。

```bash
easydict://readValueOfKey?EZOpenAIAPIKey
```

#### OpenAI 查询模式

目前 OpenAI 支持三种查询模式：单词，句子和长翻译，默认都是开启的，其中单词和句子也可关闭。

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/2KIWfp-1695612945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/tCMiec-1695637289.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/qNk8ND-1695820293.png">
</table>

考虑到 OpenAI 的 token 费用因素，因此提供默认关闭选项，写入下面命令后，OpenAI 将默认关闭查询，仅在用户手动点击展开按钮时才查询

```bash
easydict://writeKeyValue?EZOpenAIServiceUsageStatusKey=1
```

```bash
// 关闭查单词
easydict://writeKeyValue?EZOpenAIDictionaryKey=0

// 关闭句子分析
easydict://writeKeyValue?EZOpenAISentenceKey=0
```
温馨提示：如果你只是偶尔不希望分析句子，可以不用关闭句子类型，只需要在【句子】后面添加一个波浪符～，这样就会变成翻译类型了。

<img width="475" alt="image" src="https://github.com/tisfeng/Easydict/assets/25194972/b8c2f0e3-a263-42fb-9cb0-efc68b8201c3">


#### OpenAI 自定义参数

支持设置自定义域名和模型

```bash
// xxx 是完整的请求地址，例如 https://api.ohmygpt.com/azure/v1/chat/completions
easydict://writeKeyValue?EZOpenAIEndPointKey=xxx

//  xxx 默认是 gpt-3.5-turbo-1106（目前最便宜实用的模型）
easydict://writeKeyValue?EZOpenAIModelKey=xxx
```

由于 OpenAI 官方接口对用户 IP 有限制，因此如果你需要反向代理，可以参考这个反代项目 [cloudflare-reverse-proxy](https://github.com/gaboolic/cloudflare-reverse-proxy)

### Gemini 翻译

[Gemini 翻译](https://gemini.google.com/) 需要 API key，可在官网[控制台](https://makersuite.google.com/app/apikey)免费获取。

```bash
easydict://writeKeyValue?EZGeminiAPIKey=xxx
```

### DeepL 翻译

DeepL 免费版网页 API 对用户单个 IP 有频率限制，频繁使用会触发 429 too many requests 报错，因此 1.3.0 版本增加了对 DeepL 官方 API 的支持，暂时还没写界面，需通过命令方式启用。

如果你有 DeepL AuthKey，建议使用个人的 AuthKey，这样可以避免频率限制，用户体验会更好。如果没有，可以使用切换代理来规避 429 报错。

> [!NOTE]
> 切换代理 IP，这是通用的解决方案，对其他有频率限制的服务同样有效。

#### 配置 AuthKey

在输入框输入下面代码，xxx 是你的 DeepL AuthKey，然后 Enter

```bash
easydict://writeKeyValue?EZDeepLAuthKey=xxx
```

#### 自定义 DeepL 接口地址

如果没有自己的 AuthKey，又需要大量使用 DeepL 翻译，那么可以考虑自己部署支持 DeepL 的接口服务，或者使用支持 DeepL 的第三方服务。

这种情况需要设置自定义 DeepL 接口地址，其中 EZDeepLTranslateEndPointKey 的值应该是完整的请求 URL，例如 DeepL 官方接口是 https://api-free.deepl.com/v2/translate ,如果自定义接口需要 AuthKey，配置方式和前面一样，接口参数和 DeepL 官方保持一致。

使用自定义 DeepL 接口地址的方式，在 Easydict 程序中等同于 DeepL 官方 AuthKey API 形式。

```bash
easydict://writeKeyValue?EZDeepLTranslateEndPointKey=xxx
```
借助下面开源项目，可以在自己的服务器或者 Cloudflare 上部署支持 DeepL 翻译的接口服务：

- [deeplx-for-cloudflare](https://github.com/ifyour/deeplx-for-cloudflare)
- [DeepLX](https://github.com/OwO-Network/DeepLX)


#### 配置 API 调用方式

1. 默认优先使用网页版 API，在网页版 API 失败时会使用个人的 AuthKey（如果有）

```bash
easydict://writeKeyValue?EZDeepLTranslationAPIKey=0
```

2. 优先使用个人的 AuthKey，失败时使用网页版 API。若高频率使用 DeepL，建议使用这种方式，能减少一次失败的请求，提高响应速度。

```bash
easydict://writeKeyValue?EZDeepLTranslationAPIKey=1
```

3. 只使用个人的 AuthKey

```bash
easydict://writeKeyValue?EZDeepLTranslationAPIKey=2
```

### 腾讯翻译

[腾讯翻译](https://fanyi.qq.com/) 需要 API key，为使用方便，我们内置了一个 key，这个 key 有额度限制，不保证一直能用。

建议使用自己的 API key，每个注册用户腾讯翻译每月赠送 500 万字符流量，足以日常使用了。

```bash
// xxx 腾讯翻译的 SecretId
easydict://writeKeyValue?EZTencentSecretId=xxx

// xxx 腾讯翻译的 SecretKey
easydict://writeKeyValue?EZTencentSecretKey=xxx
```

### Bing 翻译

目前 Bing 翻译使用的是网页接口，当触发频率限制 429 报错时，除了切换代理，还可以通过手动设置请求 cookie 来续命，具体续命多久暂时不清楚。

具体步骤是，使用浏览器打开 [Bing Translator](https://www.bing.com/translator)，登录，然后在控制台执行以下代码获取 cookie

```js
cookieStore.get("MUID").then(result => console.log(encodeURIComponent("MUID=" + result.value)));
```

最后将 cookie 使用命令写入 Easydict

```bash
// xxx 是前面获取的 cookie
easydict://writeKeyValue?EZBingCookieKey=xxx
```
> [!NOTE]
> Bing TTS 用的也是网页接口，同样容易触发接口限制，且不会报错提示，因此如果将 Bing 设为默认的 TTS，建议设置 cookie。

### 小牛翻译

[小牛翻译](https://niutrans.com/) 需要 API key，为使用方便，我们内置了一个 key，这个 key 有额度限制，不保证一直能用。

建议使用自己的 API key，每个注册用户小牛翻译每日赠送 20 万字符流量。

```bash
// xxx 小牛翻译的 APIKey
easydict://writeKeyValue?EZNiuTransAPIKey=xxx
```

### 彩云小译

[彩云小译](https://fanyi.caiyunapp.com/) 需要 Token，为使用方便，我们内置了一个 token，这个 token 有一定限制，不保证一直能用。

建议使用自己的 Token，新用户注册会获得 100 万字的免费翻译额度。

```bash
// xxx 彩云小译的 Token
easydict://writeKeyValue?EZCaiyunToken=xxx
```

### 阿里翻译

[阿里翻译](https://translate.alibaba.com/) 虽然目前支持网页版接口，但这个接口有一定限制，不保证一直能用。

建议使用自己的 API key，阿里翻译每月免费额度一百万字符。

```bash
easydict://writeKeyValue?EZAliAccessKeyId=xxx
easydict://writeKeyValue?EZAliAccessKeySecret=xxx
```

## 智能查询模式

目前查询服务主要分为两类：查询单词（如苹果词典）和翻译文本（如 DeepL），另外有些服务（如有道和谷歌），同时支持查询单词和翻译文本。

```objc
typedef NS_OPTIONS(NSUInteger, EZQueryTextType) {
    EZQueryTextTypeNone = 0, // 0
    EZQueryTextTypeTranslation = 1 << 0, // 01 = 1
    EZQueryTextTypeDictionary = 1 << 1, // 10 = 2
    EZQueryTextTypeSentence = 1 << 2, // 100 = 4
};
```

Easydict 可以根据查询文本的内容，自动启用相应的查询服务。

具体来说，在智能查询模式下，当查询单词时，则只会调用支持【单词查询】的服务；当翻译文本时，则只会调用支持【文本翻译】的服务。

对于单词，支持查询单词的服务效果明显比翻译更好，而翻译文本时，启用单词查询服务

默认情况下，所有的翻译服务都支持单词查询（单词也属于文本的一种），用户可以手动调整，如设置 Google 智能模式只翻译文本，只需要使用下面命令修改为 `translation | sentence` 即可。

```bash
easydict://writeKeyValue?Google-IntelligentQueryTextType=5  
```

同样，对于一些同时支持查询单词和翻译文本的服务，如有道词典，也可以设置它智能模式只查询单词，设置类型为 `dictionary`

```bash
easydict://writeKeyValue?Youdao-IntelligentQueryTextType=2
```

默认情况下，只有【迷你窗口】启用了智能查询模式，用户也可以手动对【侧悬浮窗口】启用智能查询模式：

```bash
easydict://writeKeyValue?IntelligentQueryMode-window2=1
```
window1 代表迷你窗口，window2 代表侧悬浮窗口，赋值 0 表示关闭，1 表示开启。

> [!NOTE]
> 智能查询模式，只表示是否智能启用该查询服务，用户可随时手动点击服务右侧箭头按钮展开查询。

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001112741097-1696130861.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001115013334-1696132213.png">
</table>

### 应用内查询

支持 Easydict 应用内便捷查询。在输入框或翻译结果，如遇到不熟悉的单词，可通过重压右击唤出菜单，选择第一个“应用内查询”。

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231019101421740-1697681661-1697681993.png" width="50%" />
</div>


## URL Scheme

Easydict 支持 URL scheme 快速查询：`easydict://query?text=xxx`，如 `easydict://query?text=good`。 

如果查询内容 xxx 包含特殊字符，需进行 URL encode，如 `easydict://query?text=good%20girl`。 

> [!WARNING]
> 旧版本的 easydict://xxx 在某些场景下可能会出现问题，因此建议使用完整的 URL Scheme:
> easydict://query?text=xxx

## 配合 PopClip 使用

你需要先安装 [PopClip](https://pilotmoon.com/popclip/)，然后选中以下代码块，`PopClip` 会显示 "安装扩展 Easydict"，点击它即可。

```applescript
-- #popclip
-- name: Easydict
-- icon: iconify:ri:translate
-- language: applescript
tell application "Easydict"
  launch
  open location "easydict://query?text={popclip text}"
end tell
```

![image-20231215193536900](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231215193536900-1702640137.png)

> 参考：https://www.popclip.app/dev/applescript-actions

## 设置

设置页提供了一些设置修改，如开启查询后自动播放单词发音，修改翻译快捷键，开启、关闭服务，或调整服务顺序等。

### 通用

![dYtfPh-1684758870](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/dYtfPh-1684758870.png)

### 服务

Easydict 有 3 种窗口类型，可以分别为它们设置不同的服务。

- 迷你窗口：鼠标自动划词时显示。
- 侧悬浮窗口：快捷键划词和截图翻译时显示。
- 主窗口：默认关闭，可在设置中开启，程序启动时显示。（稍后会增强主窗口功能）

![iShot_2023-01-20_11.47.34-1674186506](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.47.34-1674186506.png)

## 应用内快捷键

Easydict 有一些应用内快捷键，方便你在使用过程中更加高效。

不同于前面的翻译快捷键全局生效，下面这些快捷键只在 Easydict 窗口前台显示时生效。

<div style="display: flex; justify-content: space-between;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Mlw8ty-1681955887.png" width="50%">
</div>

- `Enter`: 输入文本后，按下 Enter 开始查询。
- `Shift + Enter`: 输入换行。
- `Cmd + ,`: 打开设置页。
- `Cmd + Q`: 退出应用。
- `Cmd + K`: 清空输入框。
- `Cmd + Shift + K`: 清空输入框和查询结果，等同于点击输入框右下角的清空按钮。
- `Cmd + I`: 聚集输入框。(Focus Input)
- `Cmd + Shift + C`: 复制查询内容。
- `Cmd + Shift + J`: 复制首个翻译结果。
- `Cmd + S`: 播放查询文本的发音。(Play Sound)
- `Cmd + R`: 再次查询。(Retry Query)
- `Cmd + T`: 交换翻译语言。(Toggle Translate Language)
- `Cmd + P`: 钉住窗口。(Pin Window，再次按下取消钉住)
- `Cmd + W`: 关闭窗口。
- `Cmd + Enter`: 默认打开 Google 搜索引擎，搜索内容为输入文本，效果等同手动点击右上角的浏览器搜索图标。
- `Cmd + Shift + Enter`: 若电脑上安装了欧路词典 App，则会在 Google 图标左边显示一个 Eudic 图标，动作为打开欧路词典 App 查询。

## Tips

只要唤醒了查询窗口，就可以通过快捷键 `Cmd + ,` 打开设置页。若不小心隐藏了菜单栏图标，可通过这种方式重新开启。

<div style="display:flex;align-items:flex-start;">
  <img src="https://user-images.githubusercontent.com/25194972/221406290-b743c5fa-75ed-4a8a-8b52-b966ac7daa68.png" style="margin-right:50px;" width="40%">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/274adbc6-8391-4386-911c-241db4a1bd98" width="30%">
</div>

若发现 OCR 识别结果不对，可通过点击”识别为 xx“按钮指定识别语言来修正 OCR 结果。

<div style="display:flex;align-items:flex-start;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230227114539063-1677469539.png" style="margin-right:40px;" width="45%">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230227114611359-1677469571.png" width="45%">
</div>

## 类似开源项目

- [immersive-translate](https://github.com/immersive-translate/immersive-translate): 一个好用的沉浸式双语网页翻译扩展。
- [pot-desktop](https://github.com/pot-app/pot-desktop) : 一个跨平台的划词翻译和 OCR 软件。
- [ext-saladict](https://github.com/crimx/ext-saladict): 沙拉查词，一个浏览器查词和翻译扩展。
- [openai-translator](https://github.com/yetone/openai-translator): 基于 ChatGPT API 的划词翻译浏览器插件和跨平台桌面端应用。
- [Raycast-Easydict](https://github.com/tisfeng/Raycast-Easydict): 我的另一个开源项目，一个 Raycast 扩展版本的 Easydict。

![easydict-1-1671806758](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/easydict-1-1671806758.png)

## 初衷

查询单词和翻译文本，是日常生活非常实用的功能，我用过很多词典翻译软件，但都不满意，直到遇见了 Bob。[`Bob`](https://bobtranslate.com/) 是一款优秀的翻译软件，但它不是开源软件，自从上架苹果商店后也不再免费提供应用更新。

作为一名开发者，也是众多开源软件的受益者，我觉得，这世界上应该存在一个免费开源版本的 [Bob](https://github.com/ripperhe/Bob)，于是我开发了 [Easydict](https://github.com/tisfeng/Easydict)。现在，我每天都在大量使用 Easydict，我很喜欢它，也希望能够让更多的人了解它、使用它。

开源，让世界更美好。

## 贡献指南

如果您对本项目感兴趣，我们非常欢迎参与到项目的贡献中，我们会尽可能地提供帮助。

目前项目主要有 dev 和 main 两个分支，dev 分支代码通常是最新的，可能包含一些正在开发中的功能。main 分支代码是稳定的，会定期合并 dev 分支的代码。

另外，我们计划将项目从 objc 向 Swift 迁移，未来逐步使用 Swift 来写新功能模块，参见 https://github.com/tisfeng/Easydict/issues/194

如果您认为项目有需要改进的地方，或者有新的功能想法，欢迎提交 PR：

如果 PR 是对已存在的 issue 进行 bug 修复或者功能实现，请提交到 dev 分支。

如果 PR 是关于某个新功能或者涉及 UI 等较大的变动，建议先开个 issue 讨论一下，避免功能重复或者冲突。

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

<table border="1">
  <tr>
    <th>Bob 初始版本</th>
    <th>Easydict 新版</th>
  </tr>
  <tr>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231224230524141-1703430324.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231224230545900-1703430346.png">
  </tr>
</table>

## 声明

Easydict 为 [GPL-3.0](https://github.com/tisfeng/Easydict/blob/main/LICENSE) 开源协议，仅供学习交流，任何人都可以免费获取该产品和源代码。如果你认为您的合法权益受到侵犯，请立即联系[作者](https://github.com/tisfeng)。你可以自由使用源代码，但必须附上相应的许可证和版权声明。

## 赞助支持

Easydict 作为一个免费开源的非盈利项目，目前主要是作者个人在开发和维护，如果你喜欢这个项目，觉得它对你有帮助，可以考虑赞助支持一下这个项目，用爱发电，让它能够走得更远。

如果发电量足够，能够 Cover 苹果的 $99 年费，我会注册一个开发者账号，以解决应用[签名问题](https://github.com/tisfeng/Easydict/issues/2)，让更多人能够方便地使用 Easydict。

<a href="https://afdian.net/a/tisfeng"><img width="20%" src="https://pic1.afdiancdn.com/static/img/welcome/button-sponsorme.jpg" alt=""></a>

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/IMG_4739-1684680971.JPG" width="30%">
</div>

### 赞助列表

如果不希望用户名显示在列表中，请选择匿名方式。感谢大家的支持！

<details> <summary> 赞助列表 </summary>

<p>

|  **日期**  |     **用户**      | **金额** |                                                          **留言**                                                           |
| :--------: | :---------------: | :------: | :-------------------------------------------------------------------------------------------------------------------------: |
| 2023-05-22 |        🍑         |    50    |                                                          感谢开源                                                           |
| 2023-05-22 |         -         |   200    |                                                                                                                             |
| 2023-05-22 |         -         |   150    |                                                                                                                             |
| 2023-05-24 |       陈佩        |    50    |      加油 有没有可能有 Linux 版？（[暂时没有](https://github.com/tisfeng/Easydict/issues/57#issuecomment-1555913845)）      |
| 2023-05-27 |      自由。       |   100    |                                                            感谢                                                             |
| 2023-06-01 |       梦遇        |    10    |                                                            感谢                                                             |
| 2023-06-05 |    挨揍的免子     |    1     |                                                           谢谢 🙏                                                           |
| 2023-06-17 |       妙才        |    5     |                                                             ❤️                                                              |
| 2023-06-19 |         1         |    20    | 加油，有没有可能调用 chatgpt 来翻译呀？（参见 [#28](https://github.com/tisfeng/Easydict/issues/28#issuecomment-1527827829)） |
| 2023-06-19 |      许冠英       |   6.6    |                                              感谢开发这么好用的软件，很喜欢。                                               |
| 2023-06-20 |    lidashuang     |    10    |                                                            感谢                                                             |
| 2023-07-03 |       小阳        |    2     |                                                                                                                             |
| 2023-07-06 |                   |    30    |                                                            谢谢                                                             |
| 2023-07-11 | 清清 🎵 在努力 ✨ |    20    |                                                                                                                             |
| 2023-07-21 |                   |    50    |                                                             ty                                                              |
| 2023-07-25 |                   |    10    |                                                          感谢开源                                                           |
| 2023-08-07 |     guanyuan      |    58    |                                                          开源万岁                                                           |
| 2023-08-29 |     非此即彼      |    5     |                                                           优雅！                                                            |
| 2023-09-04 |       aLong       |    10    |            感谢 🙏，期待功能继续完善。                                                 |
| 2023-09-13 |       一座山的秋叶       |    5    |                                                       |
| 2023-09-17 |       桂       |    200    |                  感谢开源                                     |
| 2023-09-24 |       Austen       |    10    |                  支持开源作者                                    |
| 2023-10-19 | DANIELHU | 7.3 | 感谢开源，希望能加入生词本功能。（后面会加，请等待 [33](https://github.com/tisfeng/Easydict/issues/33)） |
| 2023-10-25 | tzcsky | 10 | 非常好的软件 |
| 2023-10-26 |  | 10 | 开源万岁🎉尽点绵薄之力，感谢！ |
| 2023-11-06 | 周樹人不能沒有魯迅 | 10.66 | 有点穷，绵薄之力（囧） |
| 2023-11-07 | ㅤ HDmoli | 5 | zhihui.xiong |
| 2023-11-10 | ㅤ Andy | 5 ||
| 2023-11-12 | ㅤ  | 6.6 | 请大佬喝瓶饮料🥤，感谢开源 |
| 2023-11-13 | ㅤ御猫  | 50 | 感谢开源 |
| 2023-11-21 | ㅤ小虫  | 10 | Thank you, please keep going. |
| 2023-11-24 | ㅤ王海东  | 10 |  |
| 2023-11-25 | ㅤ jackiexiao  | 200 | 这个软件实在太太太太棒了，太感谢了 |
| 2023-11-27 | ㅤ小曹  | 50 | 感恩！Life Saver |
| 2023-11-27 | ㅤ大象🐯 | 5 | 开源，让世界更美好 |
| 2023-11-28 | ㅤ王一帆  | 5 |  |
| 2023-11-29 | ㅤ李利明  | 5 | 伟大的开发者，伟大的开源精神！（❤️） |
| 2023-11-30 | ㅤ Three  | 20 |  |
| 2023-12-02 | ㅤ翻滚的土豆  | 5 | 今天刷到一个 UP 主推荐的，加油。 |
| 2023-12-02 | ㅤ祥林叔  | 10 | 🫡 国内好的开源不多 |
| 2023-12-05 | ㅤ刘维尼  | 28.8 | 用户用'萌萌的维尼'吧 感谢开发好用又有品味的软件请您喝奶茶 |
| 2023-12-05 | ㅤ hiuxia  | 100 | 感谢这么优秀的软件！|
| 2023-12-05 | ㅤ——  | 20 |  |
| 2023-12-07 | 小逗。🎈 | 5 |  |
| 2023-12-26 | ㅤ Yee  | 5 | 感谢开源 |
| 2024-01-09 | ㅤ Jack  | 20 | 目前用过最好用的字典软件，谢谢！ |
| 2024-01-15 | ㅤ | 20 | 感谢开源，感谢有你：） |
| 2024-01-16 | ㅤ sd  | 5 | 大佬牛逼🐂🍺 |
| 2024-01-23 | ㅤ | 5 | |
| 2024-01-28 | ㅤ | 7 | |
| 2024-01-29 | 大帅ㅤ | 5 | 还没有，但是感受到了用心。|
| 2024-02-04 | ll | 20 | |
| 2024-02-10 | 盒子哥 | 100 | |
| 2024-02-26 | 吃核桃不吐皮儿 | 10 | 感谢解答问题 |
| 2024-02-28 |  | 20 | 感谢你的 Easydict |
| 2024-03-11 |  | 20 | 感谢 |
| 2024-03-16 | 幻影 | 20 | 非常感谢 |
| 2024-03-25 |  | 10 | 感谢大佬 |

</p>

</details>

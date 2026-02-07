# Easydict 完整使用指南

> 本文档包含 Easydict 的详细功能说明、配置方法和使用技巧。

## 目录

- [Easydict 完整使用指南](#easydict-完整使用指南)
  - [目录](#目录)
  - [详细功能列表](#详细功能列表)
  - [安装指南](#安装指南)
    - [手动下载安装](#手动下载安装)
    - [Homebrew 安装](#homebrew-安装)
    - [开发者构建](#开发者构建)
      - [构建环境](#构建环境)
  - [使用说明](#使用说明)
    - [鼠标划词](#鼠标划词)
    - [关于权限](#关于权限)
  - [OCR 配置](#ocr-配置)
  - [TTS 服务](#tts-服务)
  - [翻译服务配置](#翻译服务配置)
    - [🍎 苹果系统词典](#-苹果系统词典)
    - [OpenAI 翻译](#openai-翻译)
      - [OpenAI 查询模式](#openai-查询模式)
    - [内置 AI 翻译](#内置-ai-翻译)
    - [Gemini 翻译](#gemini-翻译)
    - [DeepL 翻译](#deepl-翻译)
      - [自定义 DeepL 接口地址](#自定义-deepl-接口地址)
      - [配置 API 调用方式](#配置-api-调用方式)
    - [腾讯翻译](#腾讯翻译)
    - [Bing 翻译](#bing-翻译)
    - [小牛翻译](#小牛翻译)
    - [彩云小译](#彩云小译)
    - [阿里翻译](#阿里翻译)
    - [豆包翻译](#豆包翻译)
  - [高级功能](#高级功能)
    - [URL Scheme](#url-scheme)
    - [配合 PopClip 使用](#配合-popclip-使用)
  - [设置说明](#设置说明)
    - [通用设置](#通用设置)
    - [服务设置](#服务设置)
  - [应用内快捷键](#应用内快捷键)
  - [使用技巧](#使用技巧)
  - [类似开源项目](#类似开源项目)
  - [初衷](#初衷)
  - [贡献指南](#贡献指南)

---

## 详细功能列表

- [x] 开箱即用，便捷查询单词或翻译文本。
- [x] 自动识别输入语言，自动查询目标偏好语言。
- [x] 自动划词查询，划词后自动显示查询图标，鼠标悬浮即可查询。
- [x] 支持为不同窗口配置不同的服务。
- [x] 支持智能查询模式。
- [x] 支持系统 OCR 截图翻译，静默截图 OCR。
- [x] 支持系统 TTS，支持 Bing，Google，有道和百度在线 TTS 服务。
- [x] 支持 [🍎 苹果系统词典](./How-to-use-macOS-system-dictionary-in-Easydict.md)，支持第三方词典，可手动导入 mdict 词典。
- [x] 支持 macOS 系统翻译。详情请看 [如何在 Easydict 中使用 🍎 macOS 系统翻译？](./How-to-use-macOS-system-translation-in-Easydict.md)
- [x] 支持有道词典，OpenAI，Gemini，DeepSeek，DeepL，Google，Bing，腾讯，百度，小牛，彩云，阿里，火山和豆包翻译。
- [x] 支持 48 种语言。

## 安装指南

你可以使用下面两种方式之一安装。

Easydict 最新版本支持系统 macOS 13.0+，如果系统版本为 macOS 11.0+，请使用 [2.7.2](https://github.com/tisfeng/Easydict/releases/tag/2.7.2)。

### 手动下载安装

[下载](https://github.com/tisfeng/Easydict/releases) 最新版本的 Easydict。

### Homebrew 安装

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

## 使用说明

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

## OCR 配置

目前仅支持系统 OCR，OCR 支持语言：简体中文，繁体中文，英语，日语，韩语，法语，西班牙语，葡萄牙语，德语，意大利语，俄语，乌克兰语。

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

## 翻译服务配置

### 🍎 苹果系统词典

Easydict 自动支持词典 App 中系统自带的词典，如牛津英汉汉英词典（简体中文-英语），现代汉语规范词典（简体中文）等，只需在词典 App 设置页启用相应的词典即可。

另外，苹果词典也支持自定义导入词典，因此我们可以通过导入 .dictionary 格式的词典来添加第三方词典，如简明英汉字典，朗文当代高级英语辞典等。

详情请看 [如何在 Easydict 中使用 🍎 macOS 系统词典？](./How-to-use-macOS-system-dictionary-in-Easydict.md)

<table>
 		<td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HModYw-1696150530.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
</table>

### OpenAI 翻译

1.3.0 版本开始支持 OpenAI 翻译，需要使用 OpenAI API key。

如果你没有自己的 OpenAI APIKey，可以借助一些开源项目将第三方的 LLM 接口转为标准的 OpenAI 接口，这样就能直接在 `Easydict` 中使用了。

例如 [one-api](https://github.com/songquanpeng/one-api)，one-api 是一个很好的 OpenAI 接口管理开源项目，支持多家 LLM 接口，包括 Azure、Anthropic Claude、Google Gemini、智谱 ChatGLM、百度文心一言、讯飞星火认知、阿里通义千问、360 智脑，腾讯混元，Moonshot AI，Groq，零一万物，阶跃星辰，DeepSeek，Cohere 等，可用于二次分发管理 key，仅单可执行文件，已打包好 Docker 镜像，一键部署，开箱即用。

> [!IMPORTANT]
> [2.6.0](https://github.com/tisfeng/Easydict/releases) 版本实现了新的 SwiftUI 设置页（支持 macOS 13+），支持 GUI 方式配置服务 API key，其他系统版本则需要在 Easydict 的输入框中使用命令方式配置。

> [!TIP]
> 如果电脑硬件支持，建议升级 macOS 系统，以享受更好的用户体验。

![](https://github.com/tisfeng/Easydict/assets/25194972/5b8f2785-b0ee-4a9e-bd41-1a9dd56b0231)

#### OpenAI 查询模式

目前 OpenAI 支持三种查询模式：单词，句子和长翻译，默认都是开启的，其中单词和句子也可关闭。

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/2KIWfp-1695612945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/tCMiec-1695637289.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/qNk8ND-1695820293.png">
</table>

温馨提示：如果你只是偶尔不希望分析句子，可以不用关闭句子类型，只需要在【句子】后面添加一个波浪符～，这样就会变成翻译类型了。

<img width="475" alt="image" src="https://github.com/tisfeng/Easydict/assets/25194972/b8c2f0e3-a263-42fb-9cb0-efc68b8201c3">

### 内置 AI 翻译

目前部分 LLM 服务厂商提供有限制的免费 AI 模型，例如 [Groq](https://console.groq.com)，[Google Gemini](https://aistudio.google.com/app/apikey) 等。

为方便新用户尝鲜使用这些大模型 AI 翻译，我们添加了一个内置 AI 翻译服务。

但请注意，内置的模型都有一定使用限制（主要是免费额度上的限制），我们不保证它们能一直稳定使用，建议用户还是使用 [AxonHub](https://github.com/looplj/axonhub) 等开源项目搭建自己的大模型服务。

![](https://github.com/tisfeng/Easydict/assets/25194972/6272d9aa-ddf1-47fb-be02-646ebf244248)

### Gemini 翻译

[Gemini 翻译](https://gemini.google.com/) 需要 API key，可在官网[控制台](https://makersuite.google.com/app/apikey)免费获取。

### DeepL 翻译

DeepL 免费版网页 API 对用户单个 IP 有频率限制，频繁使用会触发 429 too many requests 报错，因此 1.3.0 版本增加了对 DeepL 官方 API 的支持，暂时还没写界面，需通过命令方式启用。

如果你有 DeepL AuthKey，建议使用个人的 AuthKey，这样可以避免频率限制，用户体验会更好。如果没有，可以使用切换代理来规避 429 报错。

> [!TIP]
> 切换代理 IP，这是通用的解决方案，对其他有频率限制的服务同样有效。

#### 自定义 DeepL 接口地址

如果没有自己的 AuthKey，又需要大量使用 DeepL 翻译，那么可以考虑自己部署支持 DeepL 的接口服务，或者使用支持 DeepL 的第三方服务。

使用自定义 DeepL 接口地址的方式，在 Easydict 程序中等同于 DeepL 官方 AuthKey API 形式。

Easydict 支持 [DeepLX](https://github.com/OwO-Network/DeepLX) 接口，详情请看 [#464](https://github.com/tisfeng/Easydict/issues/464)。

#### 配置 API 调用方式

1. 默认优先使用网页版 API，在网页版 API 失败时会使用个人的 AuthKey（如果有）

2. 优先使用个人的 AuthKey，失败时使用网页版 API。若高频率使用 DeepL，建议使用这种方式，能减少一次失败的请求，提高响应速度。

3. 只使用个人的 AuthKey

### 腾讯翻译

[腾讯翻译](https://fanyi.qq.com/) 需要 API key，为使用方便，我们内置了一个 key，这个 key 有额度限制，不保证一直能用。

建议使用自己的 API key，每个注册用户腾讯翻译每月赠送 500 万字符流量，足以日常使用了。

### Bing 翻译

目前 Bing 翻译使用的是网页接口，当触发频率限制 429 报错时，除了切换代理，还可以通过手动设置请求 cookie 来续命，具体续命多久暂时不清楚。

具体步骤是，使用浏览器打开 [Bing Translator](https://www.bing.com/translator)，登录，然后在控制台执行以下代码获取 cookie

```js
cookieStore.get("MUID").then(result => console.log(encodeURIComponent("MUID=" + result.value)));
```

最后将 cookie 填写到 Easydict

> [!NOTE]
> Bing TTS 用的也是网页接口，同样容易触发接口限制，且不会报错提示，因此如果将 Bing 设为默认的 TTS，建议设置 cookie。

### 小牛翻译
    
[小牛翻译](https://niutrans.com/) 需要 API key，为使用方便，我们内置了一个 key，这个 key 有额度限制，不保证一直能用。

建议使用自己的 API key，每个注册用户小牛翻译每日赠送 20 万字符流量。

### 彩云小译

[彩云小译](https://fanyi.caiyunapp.com/) 需要 Token，为使用方便，我们内置了一个 token，这个 token 有一定限制，不保证一直能用。

建议使用自己的 Token，新用户注册会获得 100 万字的免费翻译额度。

### 阿里翻译

[阿里翻译](https://translate.alibaba.com/) 虽然目前支持网页版接口，但这个接口有一定限制，不保证一直能用。

建议使用自己的 API key，阿里翻译每月免费额度一百万字符。

### 豆包翻译

[豆包翻译](https://www.volcengine.com/docs/82379/1820188) 需要 API key，可在[火山方舟平台](https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey)进行申请。

建议使用自己的 API key，每个注册用户赠送 50 万字符的免费翻译额度。

## 高级功能

### URL Scheme

Easydict 支持 URL scheme 快速查询：`easydict://query?text=xxx`，如 `easydict://query?text=good`。 

如果查询内容 xxx 包含特殊字符，需进行 URL encode，如 `easydict://query?text=good%20girl`。 

> [!WARNING]
> 旧版本的 easydict://xxx 在某些场景下可能会出现问题，因此建议使用完整的 URL Scheme:
> easydict://query?text=xxx

### 配合 PopClip 使用

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

## 设置说明

设置页提供了一些设置修改，如开启查询后自动播放单词发音，修改翻译快捷键，开启、关闭服务，或调整服务顺序等。

### 通用设置

![](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/5IacMJ.png)

### 服务设置

Easydict 有 3 种窗口类型，可以分别为它们设置不同的服务。

- 迷你窗口：鼠标自动划词时显示。
- 侧悬浮窗口：快捷键划词和截图翻译时显示。
- 主窗口：默认关闭，可在设置中开启，程序启动时显示。

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

## 使用技巧

只要唤醒了查询窗口，就可以通过快捷键 `Cmd + ,` 打开设置页。若不小心隐藏了菜单栏图标，可通过这种方式重新开启。

<div style="display:flex;align-items:flex-start;">
  <img src="https://user-images.githubusercontent.com/25194972/221406290-b743c5fa-75ed-4a8a-8b52-b966ac7daa68.png" style="margin-right:50px;" width="40%">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/274adbc6-8391-4386-911c-241db4a1bd98" width="30%">
</div>

若发现 OCR 识别结果不对，可通过点击"识别为 xx"按钮指定识别语言来修正 OCR 结果。

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

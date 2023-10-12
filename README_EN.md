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

`Easydict` is a concise and easy-to-use translation dictionary macOS App that allows you to easily and elegantly look up words or translate text. Easydict is ready to use out of the box, can automatically recognize the language of the input text, supports input translate, select translate, and OCR screenshot translate, and can query multiple translation services result at the same time. Currently, it supports [Youdao Dictionary](https://www.youdao.com/), [**🍎Apple System Dictionary**](./docs/How-to-use-macOS-system-dictionary-in-Easydict-en.md), [**🍎macOS System Translation**](./docs/How-to-use-macOS-system-dictionary-in-Easydict-zh.md), [OpenAI(ChatGPT)](https://chat.openai.com/), [DeepL](https://www.deepl.com/translator), [Google](https://translate.google.com/), [Bing Translate](https://www.bing.com/translator), [Baidu](https://fanyi.baidu.com/), and [Volcano Translation](https://translate.volcengine.com/translate).

![Log](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Log-1688378715.png)

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.18-1685262784.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.26-1685262803.png">
</table>

![immerse-1686534718.gif](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/immerse-1686534718.gif)

## Features

- [x] Out of the box, easily look up words or translate text.
- [x] Automatic recognition of input language and automatic query of target preferred language.
- [x] Auto select translate, automatically display the query icon after word search, and mouse hover to query.
- [x] Support for configuring different services for different window types.
- [x] Support system OCR screenshot translation, Silent Screenshot OCR.
- [x] Support system TTS, along with online services from Bing, Google, Youdao and Baidu Cloud.
- [x] Support [Apple System Dictionary](./docs/How-to-use-macOS-system-dictionary-in-Easydict-en.md), support third-party dictionaries with manual mdict dictionaries import functionalities.
- [x] Support macOS system translation. (_Please see [How to use 🍎 macOS system translation in Easydict?](./docs/How-to-use-macOS-system-dictionary-in-Easydict-en.md)_)
- [x] Support Youdao Dictionary, DeepL, OpenAI (ChatGPT), Google, Bing, Baidu, and Volcano Translate.
- [x] Support for 48 languages.

**If you like this app, please consider giving it a [Star](https://github.com/tisfeng/Easydict) ⭐️, thanks! (^-^)**

---

## Table of contents

- [Easydict](#easydict)
- [Features](#features)
- [Table of contents](#table-of-contents)
- [Installation](#installation)
  - [1. Manual](#1-manual)
  - [2. Homebrew (Thanks BingoKingo）](#2-homebrew-thanks-bingokingo)
  - [Developer Build](#developer-build)
  - [Signature Problem ⚠️](#signature-problem-️)
- [Usage](#usage)
  - [Select text by Mouse](#select-text-by-mouse)
  - [About Permissions](#about-permissions)
- [OCR](#ocr)
- [Language Recognition](#language-recognition)
- [TTS Services](#tts-services)
- [Translation Services](#translation-services)
  - [Apple System Dictionary](#apple-system-dictionary)
  - [OpenAI (ChatGPT) Translation](#openai-chatgpt-translation)
    - [Configure APIKey](#configure-apikey)
    - [Query Mode](#query-mode)
    - [Customizations](#customizations)
  - [DeepL Translate](#deepl-translate)
    - [Configure AuthKey](#configure-authkey)
    - [Configure API call method](#configure-api-call-method)
  - [Bing Translate](#bing-translate)
- [Smart Query Mode](#smart-query-mode)
- [Use with PopClip](#use-with-popclip)
- [Preferences](#preferences)
  - [Settings](#settings)
  - [Services](#services)
  - [In-App Shortcuts](#in-app-shortcuts)
- [Tips](#tips)
- [Similar Open Source Projects](#similar-open-source-projects)
- [Motivation](#motivation)
- [Contributor Guide](#contributor-guide)
- [Acknowledgements](#acknowledgements)
- [Statement](#statement)
- [Sponsor](#sponsor)
  - [Sponsor List](#sponsor-list)

## Installation

You can install it using one of the following two methods. Support macOS 11.0+

### 1. Manual Installation

[Download](https://github.com/tisfeng/Easydict/releases) the latest release of the app.

### 2. Homebrew (Thanks [BingoKingo](https://github.com/tisfeng/Easydict/issues/1#issuecomment-1445286763)）

```bash
brew install easydict
```

### Developer Build

If you are a developer, or you are interested in this project, you can also try to build and run it manually. The whole process is very simple, even without knowing macOS development knowledge.

<details> <summary> Build Steps： </summary>

<p>

Just download this Repo, then use [Xcode](https://developer.apple.com/xcode/) to open the `Easydict.xcworkspace` file(⚠️ Not `Easydict.xcodeproj`!), `Cmd + R` to compile and run.

If a signature error occurs during compilation, please use your own developer account on the `Signing & Capabilities` page of the target. If you are not an Apple developer yet, just go to https://developer.apple.com/ and register for free.

If you don't want to register as an Apple developer, you can also run with automatic signature, refer to the screenshot below, change `Team` to None and `Signing Certificate` to Sign to Run Locally, note that both targets should be changed.

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-06-22_16.06.35-1687421213.png" width="100%" />
</div>

Build environment: Xcode 13+, macOS Big Sur 11.3+. To avoid unnecessary problems, it is recommended to use the latest Xcode and macOS version https://github.com/tisfeng/Easydict/issues/79

</p>

</details>

### Signature Problem ⚠️

Easydict is open source software and is inherently secure, but due to Apple's strict checking mechanism, you may encounter warning blocks when opening it.

FAQ:

1. If you encounter the following [Cannot open Easydict problem](https://github.com/tisfeng/Easydict/issues/2), please refer to [Open Mac App from an unidentified developer](https://support.apple.com/zh-cn/guide/mac-help/mh40616/mac)

> Cannot open "Easydict.dmg" because Apple cannot check to see if it contains malware.

<div >
    <img src="https://user-images.githubusercontent.com/25194972/219873635-46e9d318-7237-462b-be69-44ad7a3ea760.png" width="30%">
    <img src="https://user-images.githubusercontent.com/25194972/219873670-7ce67946-87c2-4d45-84fd-3cc59936f7be.png"  width="30%">
    <img src="https://user-images.githubusercontent.com/25194972/219873722-2e780565-fe26-4ce3-9648-f1cbdd393843.png"  width="30%">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="https://user-images.githubusercontent.com/25194972/219873809-2b407852-7f77-4aef-9206-3f6393cb7c31.png" width="100%" />
</div>

2. If it indicates that the app is corrupted, please refer to [macOS Bypassing Notary and App Signing Methods](https://www.5v13.com/sz/31695.html)

> "Easydict" is corrupted and cannot be opened.

Just type the following command in the terminal and enter the password.

```bash
sudo xattr -rd com.apple.quarantine /Applications/Easydict.app
```

---

## Usage

Once Easydict is launched, in addition to the main window (hidden by default), there will be a menu icon, and clicking on the menu option will trigger the corresponding actions, as follows:

<div>
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/f0c7da85-b9e0-4003-b673-e93f6477a75b" width="50%" />
</div>

| Ways                      | Description                                                                                                                                  | Preview                                                                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Mouse select translate    | The query icon is automatically displayed after the word is selected, and the mouse hovers over it to query                                  | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| Shortcut select translate | After selecting the text to be translated, press the shortcut key (default `⌥ + D`)                                                          | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| Screenshot translate      | Press the screenshot translate shortcut key (default `⌥ + S`) to capture the area to be translated                                           | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| Input translate           | Press the input translate shortcut key (default `⌥ + A`, or `⌥ + F`), enter the text to be translated, and `Enter` key to translate          | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |
| Silent Screenshot OCR     | Press the Silent Screenshot shortcut key（default `⌥ + ⇧ + S`）to capture the area, the OCR results will be copied directly to the clipboard | ![屏幕录制2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                    |

### Select text by Mouse

Currently, multiple mouse quick word selection methods are supported: double-click word selection, mouse drag word selection, triple-click word selection (paragraph) and Shift word selection (multiple paragraphs). In some applications, **mouse drag word selection** and **Shift word selection** may fail, in which case you can switch to other word selection methods.

The shortcut key to select words can work normally in any application. If you encounter an application that cannot select words, you can open an issue to solve it https://github.com/tisfeng/Easydict/issues/84

The flow of the crossword function: Accessibility > AppleScript > simulated shortcuts, giving priority to the secondary function Accessibility fetching, and if Accessibility fetching fails (unauthorized or not supported by the application), if it is a browser application (e.g. Safari, Chrome), it will try to use AppleScript fetching. If the AppleScript fetching still fails, then the final forced fetching is done - simulating the shortcut Cmd+C to fetch the word.

Therefore, it is recommended to turn on the Allow JavaScript in Apple events option in your browser to avoid event blocking on certain web pages, such as those with [forced copyright information](<(https://github.com/tisfeng/Easydict/issues/85)>), and to optimize the word fetching experience.

For Safari users, it is highly recommended that this option be turned on, as Safari does not support Accessibility fetching, and AppleScript fetching is far superior to simulating shortcuts.

<div>
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/a1d8aa6b-69d7-459a-ac83-a6f090d04cae" width="45%">
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/4dbf038b-d939-454f-9205-648636f46ca8" width="45%">
</div>

### About Permissions

1. `Select Translate` requires the `Auxiliary Accessibility`. The mouse stroke function only triggers the application of auxiliary accessibility permission when it is used for the first time, and the automatic stroke translation function can only be used normally after authorization.

2. For screenshot Translate, you need to enable `Screen Recording` permission. The application will only automatically pop up a permission application dialog box when you use **Screenshot Translation** for the first time. If the authorization fails, you need to turn it on in the system settings manually.

## OCR

Currently, only the system OCR is supported, third-party OCR services will be integrated later.

System OCR supported languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, Spanish, Portuguese, German, Italian, Russian, Ukrainian.

## Language Recognition

Currently, only the system language recognition is supported, and Baidu and Google language recognition are supported, but considering the speed problem of online recognition and instability (Google also needs to be flipped), the other two recognition services are only used for auxiliary optimization.

The system language recognition is used by default, and after tuning, the accuracy of the system language recognition is already very high, which can meet the needs of most users.

If you still feel that the system language recognition is inaccurate in actual use, you can turn on Baidu language recognition or Google language recognition optimization in the settings, but please note that this may cause the response speed to slow down, and the recognition rate will not be 100% in line with user expectations. If there is a recognition error, you can manually specify the language type.

## TTS Services

Currently support macOS system TTS, Bing, Google, Youdao, and Baidu online TTS service.

- System TTS: The most stable and reliable option, but not very accurate. It is usually used as a fallback option, i.e., the system TTS is used instead of the other TTS when errors occur.
- Bing TTS: Yields optimal results by generating real-time neural network speech synthesis. However, this process is more time-intensive, and the length of the input text directly impacts the duration of generation. Currently, the maximum supported character limit is 2,000 characters, roughly equivalent to a 10-minute generation time.
- Google TTS: Good results with English, and the interface is stable. However, it can only generate upto 200 characters at a time.
- Youdao TTS: The overall performance is commendable with a stable interface, and it excels in the pronunciation of English words. However, the maximum character limit is capped at 600 characters.
- Baidu TTS: English sentences are well pronounced with a distinctive accent, but can only generate up to about 1,000 characters.

By default, the application uses Youdao TTS, but users have the option to select their preferred TTS service in the settings. Due to its impressive performance with English words, Youdao TTS is the recommended choice for such content, while the default TTS service remains in use for other languages. It's worth noting that, apart from the system TTS, all other TTS services are unofficial interfaces and may experience instabilities from time to time

## Translation Services

**Currently, we support Youdao Dictionary, macOS system translation, DeepL, Google, Bing, Baidu, and Volcano translation, a total 6 translation services.**

> Note ⚠️: Since the Chinese version of Google Translate is currently unavailable, you can only use the international version, so you need to use a proxy to use Google Translate.

<details> <summary> Supported languages: </summary>

<p>

|       Languages       | Youdao | DeepL | macOS System | Bing | Google | Baidu | Volcano |
| :-------------------: | :----: | :---: | :----------: | :--: | :----: | :---: | :-----: |
| Chinese (Simplified)  |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
| Chinese (Traditional) |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        English        |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Japanese        |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Korean         |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        French         |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Spanish        |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|      Portuguese       |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Italian        |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        German         |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Russian        |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Arabic         |   ✅   |  ❌   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Swedish        |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Romanian        |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Thai          |   ✅   |  ❌   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Slovak         |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Dutch         |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Hungarian       |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Greek         |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Danish         |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Finnish        |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Polish         |   ❌   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Czech         |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Turkish        |   ❌   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|      Lithuanian       |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Latvian        |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Ukrainian       |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Bulgarian       |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|      Indonesian       |   ✅   |  ✅   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Malay         |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Slovenian       |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Estonian        |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|      Vietnamese       |   ✅   |  ❌   |      ✅      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Persian        |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Hindi         |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Telugu         |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Tamil         |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Urdu          |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Filipino        |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|         Khmer         |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|          Lao          |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Bengali        |   ❌   |  ❌   |      ❌      |  ❌  |   ✅   |  ✅   |   ✅    |
|        Burmese        |   ❌   |  ❌   |      ❌      |  ❌  |   ✅   |  ✅   |   ✅    |
|       Norwegian       |   ❌   |  ✅   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Serbian        |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Croatian        |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|       Mongolian       |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |
|        Hebrew         |   ❌   |  ❌   |      ❌      |  ✅  |   ✅   |  ✅   |   ✅    |

</p>

</details>

### Apple System Dictionary

Easydict 自动支持词典 App 中系统自带的词典，如牛津英汉汉英词典（简体中文-英语），现代汉语规范词典（简体中文）等，只需在词典 App 设置页启用相应的词典即可。

另外，苹果词典也支持自定义导入词典，因此我们可以通过导入 .dictionary 格式的词典来添加第三方词典，如简明英汉字典，朗文当代高级英语辞典等。

详情请看 [如何在 Easydict 中使用 🍎 macOS 系统词典？](./docs/How-to-use-macOS-system-dictionary-in-Easydict-en.md)

<table>
 		<td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HModYw-1696150530.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
</table>

### OpenAI (ChatGPT) Translation

1.3.0 版本开始支持 OpenAI 翻译，也支持 Azure OpenAI 接口，暂时还没写界面，需要通过命令方式启用。

请先确保你有 APIKey。


#### Configure APIKey
```
easydict://writeKeyValue?EZOpenAIAPIKey=sk-xxx
```
<bar>

查看 APIKey (其他 key 类似)，如果查询成功，会将结果写到剪贴板。
```
easydict://readValueOfKey?EZOpenAIAPIKey
```

#### Query Mode

目前 OpenAI 支持三种查询模式：单词，句子和长翻译，默认都是开启的，其中单词和句子也可关闭。

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/2KIWfp-1695612945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/tCMiec-1695637289.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/qNk8ND-1695820293.png">
</table>

考虑到 OpenAI 的 token 费用因素，因此提供默认关闭选项，写入下面命令后， OpenAI 将默认关闭查询，仅在用户手动点击展开按钮时才查询

```
easydict://writeKeyValue?EZOpenAIServiceUsageStatusKey=1
```

```
// 关闭查单词
easydict://writeKeyValue?EZOpenAIDictionaryKey=0

// 关闭句子分析
easydict://writeKeyValue?EZOpenAISentenceKey=0
```
温馨提示：如果你只是偶尔不希望分析句子，可以不用关闭句子类型，只需要在【句子】后面添加一个波浪符～，这样就会变成翻译类型了。

<img width="475" alt="image" src="https://github.com/tisfeng/Easydict/assets/25194972/b8c2f0e3-a263-42fb-9cb0-efc68b8201c3">


#### Customizations

支持设置自定义域名和模型

```
//  xxx 是 host，默认是 api.openai.com
easydict://writeKeyValue?EZOpenAIDomainKey=xxx

// xxx 是完整的请求地址，例如 https://api.ohmygpt.com/azure/v1/chat/completions
easydict://writeKeyValue?EZOpenAIEndPointKey=xxx

//  xxx 默认是 gpt-3.5-turbo
easydict://writeKeyValue?EZOpenAIModelKey=xxx
```

由于 OpenAI 官方接口对用户 IP 有限制，因此如果你需要反向代理，可以参考这个反代项目 [cloudflare-reverse-proxy](https://github.com/gaboolic/cloudflare-reverse-proxy)

### DeepL Translate

DeepL free version web API has a frequency limit for single IP, frequent use will trigger 429 too many requests error, so version 1.3.0 adds support for DeepL official API, but the interface has not been written yet, and needs to be enabled through command.

If you have DeepL AuthKey, it is recommended to use personal AuthKey, so as to avoid frequency limits and improve user experience. If not, you can use the way of switching proxy IP to avoid 429 error.

> Note: Using a new proxy IP is a generic solution that works for other frequency-limited services.

#### Configure AuthKey

Enter the following code in the input box, xxx is your DeepL AuthKey, and then Enter

```
easydict://writeKeyValue?EZDeepLAuthKey=xxx
```

#### Configure API call method

1. The web version API is used by default, and the personal AuthKey will be used when the web version API fails (if any)

```
easydict://writeKeyValue?EZDeepLTranslationAPIKey=0
```

2. Use personal AuthKey first, and use web version API when it fails. If you use DeepL frequently, it is recommended to use this method, which can reduce one failed request and improve response speed.

```
easydict://writeKeyValue?EZDeepLTranslationAPIKey=1
```

3. Only use personal AuthKey

```
easydict://writeKeyValue?EZDeepLTranslationAPIKey=2
```

### Bing Translate

目前 Bing 翻译使用的是网页接口，当触发频率限制 429 报错时，除了切换代理，还可以通过手动设置请求 cookie 来续命，具体续命多久暂时不清楚。

具体步骤是，使用浏览器打开 [Bing Translator](https://www.bing.com/translator)，登录，然后在控制台执行以下代码获取 cookie

```js
cookieStore.get("MUID").then(result => console.log(encodeURIComponent("MUID=" +result.value)));
```

最后将 cookie 使用命令写入 Easydict

```
// xxx 是前面获取的 cookie
easydict://writeKeyValue?EZBingCookieKey=xxx
```

## Smart query mode

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

```
easydict://writeKeyValue?Google-IntelligentQueryTextType=5  
```

同样，对于一些同时支持查询单词和翻译文本的服务，如有道词典，也可以设置它智能模式只查询单词，设置类型为 `dictionary`

```
easydict://writeKeyValue?Youdao-IntelligentQueryTextType=2
```

默认情况下，只有【迷你窗口】启用了智能查询模式，用户也可以手动对【侧悬浮窗口】启用智能查询模式：

```
easydict://writeKeyValue?IntelligentQueryMode-window2=1
```
window1 代表迷你窗口，window2 代表侧悬浮窗口，后面的 0 表示关闭，1 表示开启。

>  注意：智能查询模式，只表示是否智能启用该查询服务，用户可随时手动点击服务右侧箭头展开查询。

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001112741097-1696130861.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001115013334-1696132213.png">
</table>

## URL Scheme

Easydict 支持 URL scheme 快速查询：`easydict://xxx`，如 easydict://good。 

如果查询内容 xxx 包含特殊字符，需进行 URL encode，如 easydict://good%2Fgirl

## Use with PopClip

You need to install [PopClip](https://pilotmoon.com/popclip/) first, then set a shortcut key for `Easydict`, default is `Opt + D`, then you can open `Easydict` quickly with `PopClip`!

Usage: Select the following code block, `PopClip` will show "Install Easydict", just click it.

> Note ⚠️: If you have modified the default shortcut key, you need to modify the shortcut `key combo` in the script below accordingly.

```
  # popclip
  name: Easydict
  icon: square E
  key combo: option D
```

> Ref: https://github.com/pilotmoon/PopClip-Extensions#key-combo-string-format

## Preferences

The settings page provides some preference setting modifications, such as automatically playing word pronunciation after turning on a query, modifying translation shortcut keys, turning on and off services, or adjusting the order of services, etc.

### Settings

<img width="1036" alt="Prefences" src="https://github.com/Jerry23011/Easydict/assets/89069957/7d63ad8e-927f-44e2-bc14-9d2199a927e4">

### Services

Easydict has 3 types of windows and you can set different services for each of them.

- Mini window: displayed when the mouse automatically picks up words.
- Floating window: displayed when shortcut keys are used to fetch words and screenshot translation.
- Main window: hidden by default, you can turn it on in the settings and show it when the program starts. (The main window function will be enhanced later)

<img width="1330" alt="Services" src="https://github.com/Jerry23011/Easydict/assets/89069957/b3185b45-c593-4a23-a1be-0601bf347c30">

### In-App Shortcuts

Easydict has some in-app shortcuts to help you use it more efficiently.

Unlike the translation shortcut keys that are globally effective, the following shortcuts only take effect when the Easydict window is in the foreground.

<div style="display: flex; justify-content: space-between;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Mlw8ty-1681955887.png" width="50%">
</div>

- `Enter`: After entering the text, press Enter to start the query.
- `Shift + Enter`: Enter a new line.
- `Cmd + ,`: Open the settings page.
- `Cmd + Q`: Quit the app.
- `Cmd + K`: Clear the input text.
- `Cmd + Shift + K`: Clear the input box and query results, the same as clicking the clear button in the lower right corner of the input text.
- `Cmd + I`: Focus on the input text.
- `Cmd + Shift + C`: Copy query text.
- `Cmd + S`: Play the pronunciation of the query text.
- `Cmd + R`: Query again.
- `Cmd + T`: Toggle translation language.
- `Cmd + P`: Pin the window.
- `Cmd + W`: Close the window.
- `Cmd + Enter`: By default, the Google search engine is opened, and the content to be searched is the input text, which is equivalent to manually clicking the browser search icon in the upper right corner.
- `Cmd + Shift + Enter`: If the Eudic App is installed on the computer, an Eudic icon will be displayed to the left of the Google icon, and the action is to open the Eudic App to query.

## Tips

As long as the query window is activated, you can open the settings page by shortcut key `Cmd + ,`. If you hide the menu bar icon, you can reopen it in this way.

<div style="display:flex;align-items:center;">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/584bb1b3-6ddd-4af8-a8b5-fc491a21605c" style="margin-right:50px;" width="40%">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/dfdda624-68eb-4534-968a-b7327201d880" width="30%">
</div>

If you find that the OCR result is incorrect, you can correct the OCR result by clicking the "Detected xxx" button to specify the recognition language.

<div style="display:flex;align-items:flex-start;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230227114539063-1677469539.png" style="margin-right:40px;" width="45%">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230227114611359-1677469571.png" width="45%">
</div>

## Similar Open Source Projects

- [immersive-translate](https://github.com/immersive-translate/immersive-translate): A nice Immersive Dual Web Page Translation Extension.
- [ext-saladict](https://github.com/crimx/ext-saladict): A browser extension for looking up words and translating.
- [openai-translator](https://github.com/yetone/openai-translator): Browser extension and cross-platform desktop application for translation based on ChatGPT API.
- [Raycast-Easydict](https://github.com/tisfeng/Raycast-Easydict): My other open source project, a Raycast extension version of Easydict.

![easydict-1-1671806758](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/easydict-1-1671806758.png)

## Motivation

Looking up words and translating text is a very useful function in daily life. I have used many translation dictionaries, but I was not satisfied until I met Bob. [`Bob`](https://bobtranslate.com/) is an excellent translation software, but it is not open source and no longer provides free application updates since it hit the Apple Store.

As a developer and beneficiary of a lot of open source software, I think that there should be a free open source version of [Bob](https://github.com/ripperhe/Bob) in the world, so I made [Easydict](https://github.com/tisfeng/Easydict).

Now I use Easydict a lot every day, I like it very much, and I hope more people can know it and use it.

Open source makes the world better.

## Contributor Guide

If you are interested in this project, we welcome you to contribute to the project, and we will provide help as much as possible.

Currently, the project has two main branches, dev and master. The dev branch code is usually the latest, and may contain some features that are under development. The master branch code is stable and will be merged with the dev branch code regularly.

If you think there is room for improvement in the project, or if you have new ideas for features, please submit a PR:

If the PR is a bug fix or feature implementation for an existing issue, please submit it to the dev branch.

If the PR is about a new feature or involves UI changes, it is recommended to open an issue first to discuss it, to avoid duplicate or conflicting features.

## Acknowledgements

- This project was inspired by [saladict](https://github.com/crimx/ext-saladict) and [Bob](https://github.com/ripperhe/Bob), and the initial version was made based on [Bob (GPL-3.0)](https://github.com/1xiaocainiao/Bob). [Easydict](https://github.com/tisfeng/Easydict) has made many improvements and optimizations on the original project, and many features and UI are referenced from Bob.
- Screenshot feature is based on [isee15](https://github.com/isee15) 's [Capture-Screen-For-Multi-Screens-On-Mac](https://github.com/isee15/Capture-Screen-For-Multi-Screens-On-Mac), and optimized on this project.
- Select text feature is referenced from [PopClip](https://pilotmoon.com/popclip/).

## Statement

Easydict is licensed under the [GPL-3.0](https://github.com/tisfeng/Easydict/blob/main/LICENSE) open source license, which is for learning and communication only. Anyone can get this product and source code for free. If you believe that your legal rights have been violated, please contact the [author](https://github.com/tisfeng) immediately. You can use the source code freely, but you must attach the corresponding license and copyright.

## Sponsor

Easydict is a free and open source project, currently mainly developed and maintained by the author. If you like this project, and find it helpful, you can consider sponsoring this project to support it, so that it can go further.

If sponsorship is enough to cover Apple's $99 annual fee, I will sign up for a developer account to solve the app [signature problem](https://github.com/tisfeng/Easydict/issues/2) and make Easydict more accessible to more people.

<a href="https://afdian.net/a/tisfeng"><img width="20%" src="https://pic1.afdiancdn.com/static/img/welcome/button-sponsorme.jpg" alt=""></a>

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/IMG_4739-1684680971.JPG" width="30%">
</div>

### Sponsor List

If you don't want your username to be displayed in the list, please choose anonymous.

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
| 2023-06-19 |         1         |    20    | 加油，有没有可能调用 chatgpt 来翻译呀？（参见[#28](https://github.com/tisfeng/Easydict/issues/28#issuecomment-1527827829)） |
| 2023-06-19 |      许冠英       |   6.6    |                                              感谢开发这么好用的软件，很喜欢。                                               |
| 2023-06-20 |    lidashuang     |    10    |                                                            感谢                                                             |
| 2023-07-03 |       小阳        |    2     |                                                                                                                             |
| 2023-07-06 |                   |    30    |                                                            谢谢                                                             |
| 2023-07-11 | 清清 🎵 在努力 ✨ |    20    |                                                                                                                             |
| 2023-07-21 |                   |    50    |                                                             ty                                                              |
| 2023-07-25 |                   |    10    |                                                          感谢开源                                                           |
| 2023-08-07 |     guanyuan      |    58    |                                                          开源万岁                                                           |
| 2023-08-29 |     非此即彼      |    5     |                                                           优雅！                                                            |
| 2023-09-04 |       aLong       |    10    |                                                 感谢 🙏，期待功能继续完善。                                                 |
| 2023-09-13 |       一座山的秋叶       |    5    |                                                       |
| 2023-09-17 |       桂       |    200    |                  感谢开源                                     |
| 2023-09-24 |       Austen       |    10    |                  支持开源作者                                    |
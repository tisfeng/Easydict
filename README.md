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

`Easydict` 是一个简洁易用的词典翻译 macOS App，能够轻松优雅地查找单词或翻译文本。Easydict 开箱即用，能自动识别输入文本语言，支持输入翻译，划词翻译和 OCR 截图翻译，可同时查询多个翻译服务结果，目前支持[有道词典](https://www.youdao.com/)，🍎**苹果系统翻译**，[DeepL](https://www.deepl.com/translator)，[谷歌](https://translate.google.com)，[百度](https://fanyi.baidu.com/)和[火山翻译](https://translate.volcengine.com/translate)。

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
- [x] 支持系统 OCR 截图翻译，静默截图 OCR。
- [x] 支持系统 TTS。
- [x] 支持 macOS 系统翻译。详情请看 [如何在 Easydict 中使用 🍎 macOS 系统翻译？](https://github.com/tisfeng/Easydict/blob/main/docs/How-to-use-macOS-system-translation-in-Easydict-zh.md)
- [x] 支持有道词典，DeepL，Google，百度和火山翻译。
- [x] 支持 48 种语言。

下一步：

- [ ] 支持翻译服务用户 API 调用。
- [ ] 支持更多查询服务。
- [ ] 支持 macOS 系统词典。

_**如果觉得这个应用还不错，给个 [Star](https://github.com/tisfeng/Easydict) ⭐️ 支持一下吧 (^-^)**_

---

## 目录

- [Easydict](#easydict)
- [功能](#功能)
- [目录](#目录)
- [安装](#安装)
  - [1. 手动下载安装](#1-手动下载安装)
  - [2. Homebrew 安装 （感谢 BingoKingo）](#2-homebrew-安装-感谢-bingokingo)
  - [开发者构建](#开发者构建)
  - [签名问题 ⚠️](#签名问题-️)
- [使用](#使用)
  - [鼠标划词](#鼠标划词)
  - [关于权限](#关于权限)
- [OCR](#ocr)
- [语种识别](#语种识别)
- [翻译服务](#翻译服务)
  - [DeepL 翻译](#deepl-翻译)
    - [配置 AuthKey](#配置-authkey)
    - [配置 API 调用方式](#配置-api-调用方式)
- [配合 PopClip 使用](#配合-popclip-使用)
- [偏好设置](#偏好设置)
  - [设置](#设置)
  - [服务](#服务)
- [应用内快捷键](#应用内快捷键)
- [Tips](#tips)
- [类似开源项目](#类似开源项目)
- [初衷](#初衷)
- [致谢](#致谢)
- [声明](#声明)
- [赞助支持](#赞助支持)
  - [赞助列表](#赞助列表)

## 安装

你可以使用下面两种方式之一安装。支持系统 macOS 11.0+

### 1. 手动下载安装

[下载](https://github.com/tisfeng/Easydict/releases) 最新版本的 Easydict。

### 2. Homebrew 安装 （感谢 [BingoKingo](https://github.com/tisfeng/Easydict/issues/1#issuecomment-1445286763)）

```bash
brew install easydict
```

### 开发者构建

如果你是一名开发者，或者对这个项目感兴趣，也可以尝试手动构建运行，整个过程非常简单，甚至不需懂 macOS 开发知识。

<details> <summary> 构建步骤： </summary>

<p>

只需要下载这个 Repo，然后使用 [Xcode](https://developer.apple.com/xcode/) 打开 `Easydict.xcworkspace` 文件（⚠️ 不是 `Easydict.xcodeproj`!），`Cmd + R` 编译运行即可。

如果编译出现签名错误，请在 target 的 `Signing & Capabilities` 页面改用你自己的开发者账号。如果你还不是苹果开发者，只要去 https://developer.apple.com/ 免费注册一下就可以。

如果不想注册苹果开发者，也可以用自动签名方式运行，参考下面截图，将 `Team` 改为 None，`Signing Certificate` 设置为 Sign to Run Locally，注意两个 target 都要改。

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-06-22_16.06.35-1687421213.png" width="100%" />
</div>

构建环境：Xcode 13+, macOS Big Sur 11.3+。 为避免不必要的问题，建议使用最新的 Xcode 和 macOS 版本 https://github.com/tisfeng/Easydict/issues/79

</p>

</details>

### 签名问题 ⚠️

Easydict 是开源软件，本身是安全的，但由于苹果严格的检查机制，打开时可能会遇到警告拦截。

常见问题：

1. 如果遇到下面 [无法打开 Easydict 问题](https://github.com/tisfeng/Easydict/issues/2)，请参考苹果使用手册 [打开来自身份不明开发者的 Mac App](https://support.apple.com/zh-cn/guide/mac-help/mh40616/mac)

> 无法打开“Easydict.dmg”，因为它来自身份不明的开发者。

<div>
    <img src="https://user-images.githubusercontent.com/25194972/219873635-46e9d318-7237-462b-be69-44ad7a3ea760.png" width="30%">
    <img src="https://user-images.githubusercontent.com/25194972/219873670-7ce67946-87c2-4d45-84fd-3cc59936f7be.png" width="30%">
    <img src="https://user-images.githubusercontent.com/25194972/219873722-2e780565-fe26-4ce3-9648-f1cbdd393843.png" width="30%">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="https://user-images.githubusercontent.com/25194972/219873809-2b407852-7f77-4aef-9206-3f6393cb7c31.png" width="100%" />
</div>

2. 如果提示应用已损坏，请参考 [macOS 绕过公证和应用签名方法](https://www.5v13.com/sz/31695.html)

> “Easydict” 已损坏，无法打开。

在终端里输入以下命令，并输入密码即可。

```bash
sudo xattr -rd com.apple.quarantine /Applications/Easydict.app
```

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
| 静默截图 OCR   | 按下静默截图快捷键（默认 `⌥ + ⇧ + S`），截取需要 OCR 的区域，截图 OCR 结果将自动保存到剪贴板 | ![屏幕录制2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                    |
|                |

### 鼠标划词

目前支持多种鼠标快捷划词方式：双击划词、鼠标滑动划词、三击划词（段落）和 Shift 划词（多段落），在某些应用中【鼠标滑动划词】可能会失败，此时可换其他划词方式。

快捷键划词在任意应用中都可以正常工作。如遇到不能鼠标划词的应用，可提 issue 解决 https://github.com/tisfeng/Easydict/issues/84

划词功能流程：Accessibility > AppleScript > 模拟快捷键，优先使用辅助功能 Accessibility 取词，在 Accessibility 取词失败（未授权或应用不支持）时，如果是浏览器应用（如 Safari, Chrome），会尝试使用 AppleScript 取词。若 AppleScript 取词还是失败，最后则进行强制取词——模拟快捷键 Cmd+C 取词。

因此，建议开启浏览器中的 `允许 Apple 事件中的 JavaScript` 选项，这样可以避免某些网页的事件拦截，例如这种 [网页强制附带版权信息](https://github.com/tisfeng/Easydict/issues/85) 问题，优化取词体验。对于 Safari 用户，强烈建议开启该选项，因为 Safari 不支持 Accessibility 取词，而 AppleScript 取词体验远优于模拟快捷键取词。

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

如果在实际使用中还是觉得系统语种识别不准确，可在设置中开启百度语种识别或 Google 语种识别优化，但请注意，这可能会导致响应速度变慢，而且识别率也不会 100% 符合用户期望。如遇到识别有误情况，可手动指定语种类型。

## 翻译服务

**目前支持有道词典，苹果系统翻译，DeepL，Google，百度和火山翻译服务。**

> 注意 ⚠️： Google 翻译中国版已无法使用，只能使用国际版，因此需要走代理才能使用 Google 翻译。

<details> <summary> 翻译服务支持语言： </summary>

<p>

| 语言         | 有道词典 | 🍎 系统翻译 | DeepL 翻译 | Google 翻译 | 百度翻译 | 火山翻译 |
| :----------- | :------: | :---------: | :--------: | :---------: | :------: | :------: |
| 中文（简体） |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 中文（繁体） |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 英语         |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 日语         |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 韩语         |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 法语         |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 西班牙语     |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 葡萄牙语     |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 意大利语     |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 德语         |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 俄语         |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 阿拉伯语     |    ✅    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
| 瑞典语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 罗马尼亚语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 泰语         |    ✅    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
| 斯洛伐克语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 荷兰语       |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 匈牙利语     |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 希腊语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 丹麦语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 芬兰语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 波兰语       |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 捷克语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 土耳其语     |    ❌    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
| 立陶宛语     |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 拉脱维亚语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 乌克兰语     |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 保加利亚语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 印尼语       |    ✅    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 马来语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 斯洛文尼亚语 |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 爱沙尼亚语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 越南语       |    ✅    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
| 波斯语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 印地语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 泰卢固语     |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 泰米尔语     |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 乌尔都语     |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 菲律宾语     |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 高棉语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 老挝语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 孟加拉语     |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 缅甸语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 挪威语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 塞尔维亚语   |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 克罗地亚语   |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 蒙古语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 希伯来语     |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |

</p>

</details>

### DeepL 翻译

DeepL 免费版网页 API 对用户单个 IP 有频率限制，频繁使用会触发 429 too many requests 报错，因此 1.3.0 版本增加了对 DeepL 官方 API 的支持，暂时还没写界面，需通过命令方式启用。

如果你有 DeepL AuthKey，建议使用个人的 AuthKey，这样可以避免频率限制，用户体验会更好。如果没有，可以使用切换代理 IP 的方式来规避 429 报错。

#### 配置 AuthKey

在输入框输入下面代码，xxx 是你的 DeepL AuthKey，然后 Enter

```
easydict://writeKeyValue?EZDeepLAuthKey=xxx
```

#### 配置 API 调用方式

1. 默认优先使用网页版 API，在网页版 API 失败时会使用个人的 AuthKey （如果有）

```
easydict://writeKeyValue?EZDeepLTranslationAPIKey=0
```

2. 优先使用个人的 AuthKey，失败时使用网页版 API。若高频率使用 DeepL，建议使用这种方式，能减少一次失败的请求，提高响应速度。

```
easydict://writeKeyValue?EZDeepLTranslationAPIKey=1
```

3. 只使用个人的 AuthKey

```
easydict://writeKeyValue?EZDeepLTranslationAPIKey=2
```

## 配合 PopClip 使用

你需要先安装 [PopClip](https://pilotmoon.com/popclip/)，然后为 `Easydict`设置一个快捷键，默认是 `Opt + D`，那么你就可以通过 `PopClip` 快速打开 `Easydict` 啦！

使用方法：选中以下代码块，`PopClip` 会显示 "安装 Easydict"，点击它即可。

> 注意 ⚠️: 如果你修改了默认的快捷键，你需要跟着修改下面脚本中的快捷键 `key combo`。

```
  # popclip
  name: Easydict
  icon: square E
  key combo: option D
```

> 参考: https://github.com/pilotmoon/PopClip-Extensions#key-combo-string-format

## 偏好设置

设置页提供了一些偏好设置修改，如开启查询后自动播放单词发音，修改翻译快捷键，开启、关闭服务，或调整服务顺序等。

### 设置

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
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/ee377707-c021-43b2-b9e0-65272ad42c7e" width="30%">
</div>

若发现 OCR 识别结果不对，可通过点击 ”识别为 xx“ 按钮指定识别语言来修正 OCR 结果。

<div style="display:flex;align-items:flex-start;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230227114539063-1677469539.png" style="margin-right:40px;" width="45%">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230227114611359-1677469571.png" width="45%">
</div>

## 类似开源项目

- [immersive-translate](https://github.com/immersive-translate/immersive-translate): 一个好用的沉浸式双语网页翻译扩展。
- [ext-saladict](https://github.com/crimx/ext-saladict): 沙拉查词，一个浏览器查词和翻译扩展。
- [openai-translator](https://github.com/yetone/openai-translator): 基于 ChatGPT API 的划词翻译浏览器插件和跨平台桌面端应用。
- [Raycast-Easydict](https://github.com/tisfeng/Raycast-Easydict): 我的另一个开源项目，一个 Raycast 扩展版本的 Easydict。

![easydict-1-1671806758](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/easydict-1-1671806758.png)

## 初衷

查询单词和翻译文本，是日常生活非常实用的功能，我用过很多词典翻译软件，但都不满意，直到遇见了 Bob。[`Bob`](https://bobtranslate.com/) 是一款优秀的翻译软件，但它不是开源软件，自从上架苹果商店后也不再免费提供应用更新。

作为一名开发者，也是众多开源软件的受益者，我觉得，这世界上应该存在一个免费开源版本的 [Bob](https://github.com/ripperhe/Bob)，于是我开发了 [Easydict](https://github.com/tisfeng/Easydict)。现在，我每天都在大量使用 Easydict，我很喜欢它，也希望能够让更多的人了解它、使用它。

开源，让世界更美好。

## 致谢

- 这个项目的灵感来自 [saladict](https://github.com/crimx/ext-saladict) 和 [Bob](https://github.com/ripperhe/Bob)，且初始版本是以 [Bob (GPL-3.0)](https://github.com/1xiaocainiao/Bob) 为基础开发。Easydict 在原项目上进行了许多改进和优化，很多功能和 UI 都参考了 Bob。
- 截图功能是基于 [isee15](https://github.com/isee15) 的 [Capture-Screen-For-Multi-Screens-On-Mac](https://github.com/isee15/Capture-Screen-For-Multi-Screens-On-Mac)，并在此基础上进行了优化。
- 鼠标划词功能参考了 [PopClip](https://pilotmoon.com/popclip/)。

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

如果不希望用户名显示在列表中，请选择匿名方式。

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

<p align="center">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/icon_512x512-1671278252.png" height="256">
  <h1 align="center">Easydict</h1>
  <h4 align="center"> Easy to look up words or translate text</h4>
<p align="center"> 
<a href="https://github.com/tisfeng/Easydict/blob/main/docs/README_EN.md">
        <img src="https://img.shields.io/badge/%E8%8B%B1%E6%96%87-English-green"
            alt="English README"></a>
<a href="https://github.com/tisfeng/Easydict/blob/main/README.md">
        <img src="https://img.shields.io/badge/%E4%B8%AD%E6%96%87-Chinese-green"
            alt="中文 README"></a>
<a href="https://github.com/tisfeng/easydict/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/tisfeng/easydict"
            alt="License"></a>
<a href="https://github.com/tisfeng/Easydict/releases">
        <img src="https://img.shields.io/github/downloads/tisfeng/easydict/total.svg"
            alt="Downloads"></a>
</p>

## Easydict 易词典 | [English](./docs/README_EN.md)

`Easydict` 是一个简洁易用的翻译词典 macOS App，能够轻松优雅地查找单词或翻译文本。Easydict 开箱即用，能自动识别输入文本语言，支持输入翻译，划词翻译和 OCR 截图翻译，可同时查询多个翻译服务结果，目前支持[有道词典](https://www.youdao.com/)，🍎**苹果系统翻译**，[DeepL](https://www.deepl.com/translator)，[谷歌](https://translate.google.com)，[百度](https://fanyi.baidu.com/)和[火山翻译](https://translate.volcengine.com/translate)。

**查单词**
![iShot_2023-01-28_17.40.28-1674901716](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-28_17.40.28-1674901716.png)

**翻译文本**
![iShot_2023-01-28_17.49.53-1674901731](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-28_17.49.53-1674901731.png)

## 功能

- [x] 开箱即用，便捷查询单词或翻译文本。
- [x] 自动识别输入语言，自动查询目标偏好语言。
- [x] 自动划词查询，划词后自动显示查询图标，鼠标悬浮即可查询。
- [x] 支持为不同窗口配置不同的服务。
- [x] 支持系统 OCR 截图翻译。
- [x] 支持系统 TTS。
- [x] 支持 macOS 系统翻译。详情请看 [如何在 Easydict 中使用 🍎 macOS 系统翻译？](https://github.com/tisfeng/Easydict/blob/main/docs/How-to-use-macOS-system-translation-in-Easydict-zh.md)
- [x] 支持有道词典，DeepL，Google，百度和火山翻译。
- [x] 支持 48 种语言。

下一步：

- [ ] 支持翻译服务 API 调用。
- [ ] 支持更多查询服务。
- [ ] 支持 macOS 系统词典。

_**如果觉得这个应用还不错，给个 [Star](https://github.com/tisfeng/Easydict) ⭐️ 支持一下吧 (^-^)**_

### 安装

你可以使用下面两种方式之一安装。支持系统 macOS 11.0+

#### 1. 手动下载安装

[下载](https://github.com/tisfeng/Easydict/releases) 最新版本的 Easydict。

#### 2. Homebrew 安装 （感谢 [BingoKingo](https://github.com/tisfeng/Easydict/issues/1#issuecomment-1445286763)）

```bash
brew install easydict
```

#### 开发者构建

如果你是一名开发者，或者对这个项目感兴趣，也可以尝试手动构建运行，整个过程非常简单，甚至不需懂 macOS 开发知识。

只需要下载这个 Repo，然后使用 [Xcode](https://developer.apple.com/xcode/) 打开 `Easydict.xcworkspace` 文件（⚠️ 不是 `Easydict.xcodeproj`!），`Cmd + R` 编译运行即可。

如果编译出现签名错误，请在 target 的 `Signing & Capabilities` 页面改用你自己的开发者账号。如果你还不是苹果开发者，只要去 https://developer.apple.com/ 免费注册一下就可以。

构建环境：Xcode 13 macOS, Big Sur 11.3。 为避免不必要的问题，建议使用最新的 Xcode 和 macOS 版本 https://github.com/tisfeng/Easydict/issues/79

#### 签名问题 ⚠️

Easydict 是开源软件，本身是安全的，但由于苹果严格的检查机制，打开时可能会遇到警告拦截。

<details> <summary> 常见问题： </summary>

<p>

1. 如果遇到下面 [无法打开 Easydict 问题](https://github.com/tisfeng/Easydict/issues/2)，请参考苹果使用手册 [打开来自身份不明开发者的 Mac App](https://support.apple.com/zh-cn/guide/mac-help/mh40616/mac)

> 无法打开“Easydict.dmg”，因为它来自身份不明的开发者。

<div >
    <img src="https://user-images.githubusercontent.com/25194972/219873635-46e9d318-7237-462b-be69-44ad7a3ea760.png" width="30%">
    <img src="https://user-images.githubusercontent.com/25194972/219873670-7ce67946-87c2-4d45-84fd-3cc59936f7be.png"  width="30%">
    <img src="https://user-images.githubusercontent.com/25194972/219873722-2e780565-fe26-4ce3-9648-f1cbdd393843.png"  width="30%">
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

</p>

</details>

---

### 使用

Easydict 启动之后，除了应用主界面（默认隐藏），还会有一个菜单图标，点击菜单选项即可触发相应的功能，如下所示：

<div style="display: flex; justify-content: space-between;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-04_17.01.56-1672847630.png" width="50%" />
</div> <br>

| 方式           | 描述                                                                              | 预览                                                                                                                                           |
| -------------- | --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| 鼠标划词翻译   | 划词后自动显示查询图标，鼠标悬浮即可查询                                          | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| 快捷键划词翻译 | 选中需要翻译的文本之后，按下划词翻译快捷键即可（默认 `⌥ + D`）                    | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| 截图翻译       | 按下截图翻译快捷键（默认 `⌥ + S`），截取需要翻译的区域                            | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| 输入翻译       | 按下输入翻译快捷键（默认 `⌥ + A` 或 `⌥ + F`），输入需要翻译的文本，`Enter` 键翻译 | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |

#### 鼠标取词

目前支持多种鼠标快捷取词方式：双击取词、鼠标滑动取词、Shift 取词（多段落）和三击取词（段落），在某些应用中【鼠标滑动取词】可能会失败，此时可换其他取词方式。

~~快捷键取词在任意应用中都可以正常工作~~，如遇到不能取词的应用，可提 issue 解决 https://github.com/tisfeng/Easydict/issues/84

#### 注意 ⚠️

1. 划词翻译，需要开启 `辅助功能` 权限，鼠标划词功能仅在第一次使用时会触发申请辅助功能权限，授权后才能正常使用自动划词翻译功能。

2. 截图翻译，需要开启 `屏幕录制` 权限，应用仅会在第一次使用 **截图翻译** 时会自动弹出权限申请对话框，若授权失败，后续需自己去系统设置中开启。

### OCR

目前仅支持系统 OCR，稍后会引入第三方 OCR 服务。

系统 OCR 支持语言：简体中文，繁体中文，英语，日语，韩语，法语，西班牙语，葡萄牙语，德语，意大利语，俄语，乌克兰语。

#### 静默截图 OCR

在识别文本后直接将翻译结果拷贝到剪贴板，不会显示查询窗口

### 语种识别

目前支持系统语种识别，百度和 Google 语种识别三种，但考虑到在线识别的速度问题以及不稳定性（ Google 还需要翻墙），其他两种识别服务只用于辅助优化。

默认使用系统语种识别，经调教后，系统语种识别的准确率已经很高了，能够满足大部分用户的需求。

如果在实际使用中还是觉得系统语种识别不准确，可在设置中开启百度语种识别或 Google 语种识别优化，但请注意，这可能会导致响应速度变慢，而且识别率也不会 100% 符合用户期望。如遇到识别有误情况，可手动指定语种类型。

### 翻译服务

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
| 西班牙语     |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 葡萄牙语     |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 意大利语     |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 德语         |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 俄语         |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 阿拉伯语     |    ❌    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
| 瑞典语       |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 罗马尼亚语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 泰语         |    ❌    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
| 斯洛伐克语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 荷兰语       |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
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
| 印尼语       |    ❌    |     ✅      |     ✅     |     ✅      |    ✅    |    ✅    |
| 马来语       |    ❌    |     ❌      |     ❌     |     ✅      |    ✅    |    ✅    |
| 斯洛文尼亚语 |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 爱沙尼亚语   |    ❌    |     ❌      |     ✅     |     ✅      |    ✅    |    ✅    |
| 越南语       |    ❌    |     ✅      |     ❌     |     ✅      |    ✅    |    ✅    |
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

#### DeepL 翻译

DeepL 网页免费版有频率限制，很容易触发 429 报错，因此 1.3.0 版本增加了对 DeepL 官方 API 支持，暂时还没写界面，需通过命令方式启用。

如果你有 DeepL AuthKey，建议使用个人的 AuthKey，这样可以避免频率限制， 用户体验会更好。

##### 配置 AuthKey

在输入框输入下面代码，xxx 是你的 DeepL AuthKey，然后 enter

```
easydict://writeKeyValue?EZDeepLAuthKey=xxx
```

##### 配置 API 调用方式

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

### 配合 PopClip 使用

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

### 偏好设置

设置页提供了一些偏好设置修改，如开启查询后自动播放单词发音，修改翻译快捷键，开启、关闭服务，或调整服务顺序等。

#### 设置

![image-20230429102509278](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230429102509278-1682735109.png)

#### 服务

Easydict 有 3 种窗口类型，可以分别为它们设置不同的服务。

- 迷你窗口：鼠标自动取词时显示。
- 侧悬浮窗口：快捷键取词和截图翻译时显示。
- 主窗口：默认关闭，可在设置中开启，程序启动时显示。（稍后会增强主窗口功能）

![iShot_2023-01-20_11.47.34-1674186506](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.47.34-1674186506.png)

### 应用内快捷键

Easydict 有一些应用内快捷键，方便你在使用过程中更加高效。

不同于前面的翻译快捷键全局生效，下面这些快捷键只在 Easydict 窗口前台显示时生效。

<div style="display: flex; justify-content: space-between;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Mlw8ty-1681955887.png" width="50%">
</div>

#### 应用内快捷键

- `Enter`: 输入文本后，按下 Enter 开始查询。
- `Shift + Enter`: 输入换行。
- `Cmd + ,`: 打开设置页。
- `Cmd + K`: 清空输入框。
- `Cmd + Shift + K`: 清空输入框和查询结果，等同于点击输入框右下角的清空按钮。
- `Cmd + I`: 聚集输入框。(Focus Input)
- `Cmd + S`: 播放查询文本的发音。(Play Sound)
- `Cmd + R`: 再次查询。(Retry Query)
- `Cmd + T`: 切换翻译语言。(Toggle Translate Language)
- `Cmd + P`: 钉住窗口。(Pin Window，再次按下取消钉住)
- `Cmd + W`: 关闭窗口。
- `Cmd + Enter`: 默认打开 Google 搜索引擎，搜索内容为输入文本，效果等同手动点击右上角的浏览器搜索图标。
- `Cmd + Shift + Enter`: 若电脑上安装了欧路词典 App，则会在 Google 图标左边显示一个 Eudic 图标，动作为打开欧路词典 App 查询。

## Tips

只要唤醒了查询窗口，就可以通过快捷键 `Cmd + ,` 打开设置页。若不小心隐藏了菜单栏图标，可通过这种方式重新开启。

<div style="display:flex;align-items:flex-start;">
  <img src="https://user-images.githubusercontent.com/25194972/221406290-b743c5fa-75ed-4a8a-8b52-b966ac7daa68.png" style="margin-right:50px;" width="40%">
  <img src="https://user-images.githubusercontent.com/25194972/221406302-1a5fd751-012d-42b5-9834-09d2d5913ad6.png" width="30%">
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

## 动机

查询单词和翻译文本，是日常生活非常实用的功能，我用过很多翻译词典软件，但都不满意，直到遇见了 Bob。[`Bob`](https://bobtranslate.com/) 是一款优秀的翻译软件，但它不是开源软件，自从上架苹果商店后也不再免费提供应用更新。

作为一名开发者，也是众多开源软件的受益者，我觉得，这世界上应该存在一个免费开源版本的 [Bob](https://github.com/ripperhe/Bob)，于是我开发了 [Easydict](https://github.com/tisfeng/Easydict)。现在，我每天都在大量使用 Easydict，我很喜欢它，也希望能够让更多的人了解它、使用它。

开源，让世界更美好。

## 致谢

- 这个项目的灵感来自 [saladict](https://github.com/crimx/ext-saladict) 和 [Bob](https://github.com/ripperhe/Bob)，且初始版本是以 [Bob (GPL-3.0)](https://github.com/1xiaocainiao/Bob) 为基础开发。Easydict 在原项目上进行了许多改进和优化，很多功能和 UI 都参考了 Bob。
- 截图功能是基于 [isee15](https://github.com/isee15) 的 [Capture-Screen-For-Multi-Screens-On-Mac](https://github.com/isee15/Capture-Screen-For-Multi-Screens-On-Mac)，并在此基础上进行了优化。
- 鼠标取词功能参考了 [PopClip](https://pilotmoon.com/popclip/)。

## 声明

Easydict 作为一个自由免费的开源项目，仅供学习交流，任何人均可免费获取产品与源码。如果认为你的合法权益收到侵犯请马上联系[作者](https://github.com/tisfeng)。

Easydict 为 [GPL-3.0](https://github.com/tisfeng/Easydict/blob/main/LICENSE) 开源协议，你可以随意使用源码，但必须附带该许可与版权声明。

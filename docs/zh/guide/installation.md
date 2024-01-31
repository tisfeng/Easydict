# 安装

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

### 签名问题 ⚠️

Easydict 是开源软件，本身是安全的，但由于苹果严格的检查机制，打开时可能会遇到警告拦截。

常见问题

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

> “Easydict”已损坏，无法打开。

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
| 静默截图 OCR   | 按下静默截图快捷键（默认 `⌥ + ⇧ + S`），截取需要 OCR 的区域，截图 OCR 结果将自动保存到剪贴板 | ![屏幕录制 2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                    |
|                |

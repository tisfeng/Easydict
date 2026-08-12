# 开始翻译
Easydict 的翻译是通过 Xcode 中的 String Catalog 管理的，下面是翻译 Easydict 的详细步骤
### 安装 Xcode 15+
可以从 [Mac App Store](https://apps.apple.com/app/xcode/id497799835) 安装Xcode，或者从 [Apple Developer](https://developer.apple.com/xcode/resources/) 获取 Beta 版本。
### 克隆和构建项目
1. 使用 git 将项目从 GitHub 克隆到本地，这里可以使用 [git 命令行工具](https://docs.github.com/en/get-started/getting-started-with-git) 或 [GitHub Desktop](https://desktop.github.com) 
2. 切换到 [dev](https://github.com/tisfeng/Easydict/tree/dev) 分支
3. 打开项目并构建，有关如何构建项目的详细说明在[这里](../../../README_ZH.md#开发者构建)
### 添加语言到String Catalog
现在可以添加新的语言了！
1. 找到 `Easydict -> Easydict -> App -> Localizable.xcstrings`。同时展开 `Main.storyboard` 然后找到 `Main.xcstrings (Strings)`。这两个 `.xcstrings` 是翻译要用的
2. 首先打开 `Localizable.xcstrings` 文件，然后点`+`按钮添加语言，如果找不到要做翻译的语言（例如 Canadian English），滚动到菜单底部，打开二级菜单 `More Languages`
3. 添加语言后就可以开始翻译了。不要忘记翻译 `Main.xcstring (Strings)` 中的字符串😉
### 预览翻译
在完成翻译后可以跑一下 Easydict 做检查。
1. 在 Xcode 顶部工具栏上找到 Easydict 图标，然后点击它
2. 点击 `Edit Scheme...`
3. 在侧边栏中选择 `RUN`，然后转到 `Options`
4. 向下滚动找到 `App Language`，然后选择要检查的语言
5. 关闭选项卡，然后使用快捷键 ⌘R 运行 Easydict 并检查翻译
### 将更改 push 到 GitHub
在完成本地化检查后就可以将更改 push 到 GitHub 并发起拉取请求了。
- [发起拉取请求](https://docs.github.com/zh/pull-requests)。
- 记得将合并目标设置为`dev`分支

最后等待 review 完成就可以合并到主仓库，并在下一次发版看到最新的翻译啦！
### 其他资源
- [Localization - Apple Developer](https://developer.apple.com/documentation/Xcode/localization)
- [Localizing and varying text with a string catalog - Apple Developer](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [Discover String Catalogs - WWDC23 Videos](https://developer.apple.com/videos/play/wwdc2023/10155)
- [Apple 本地化术语表](https://applelocalization.com)
- [Easydict 本地化示例 PR](https://github.com/tisfeng/Easydict/pull/668)

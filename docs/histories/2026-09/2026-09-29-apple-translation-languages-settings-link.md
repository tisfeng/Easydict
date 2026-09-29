## 2026-09-29 | 任务：添加 Apple 翻译语言设置入口

**Links:** None

### 执行上下文

- **Agent Name:** `GitHub Copilot`
- **Model:** `gpt-6-luna`
- **Environment:** `macOS 26.7 / Xcode 27.0 (27A266a)`

### 用户请求

在 Easydict 中提供直达 macOS 翻译语言管理设置的入口。

### 变更

- 将 Apple 离线翻译开关及说明移到“设置 → 服务 → Apple 翻译”的配置面板，并在说明里的“系统设置”文字嵌入直达 macOS 翻译语言设置的链接；仅 macOS 15+ 显示。
- 配置面板使用 Apple Translate 分区标题、普通无图标开关行和说明 footer，贴近其他服务设置的布局。
- 为所有现有应用语言添加内嵌链接的服务配置本地化。
- 更新中英文 Apple 翻译指南，说明新入口及快捷指令路径的实际条件。

### 设计意图

在 Apple 翻译服务配置面板复用原开关和说明，将设置入口放到服务本身的配置边界内；配置区标题和无图标行遵循其他服务设置的布局，本地化说明中的 Markdown 链接可直达系统翻译语言设置，不改动服务后端选择逻辑。

### 验证

- `xcodebuild build -quiet -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <checkout-specific-agent-derived-data>`：通过；环境中没有 `xcbeautify`，因此直接运行 `xcodebuild`。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- Swift `AttributedString(markdown:)` 检查：六种本地化均解析出唯一的 System Settings 深链接。
- `git diff --check`：通过。
- 手动检查：未启动 System Settings 验证深链接的实际导航行为。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTab.swift`
- `Easydict/Swift/Service/Apple/AppleService.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/user-docs/en/How-to-use-macOS-system-translation-in-Easydict.md`
- `docs/user-docs/zh/How-to-use-macOS-system-translation-in-Easydict.md`
- `docs/histories/2026-09/2026-09-29-apple-translation-languages-settings-link.md`

### 后续事项

- 当前系统设置入口依赖 macOS 的 `x-apple.systempreferences` URL scheme；未手动确认各 macOS 版本对 Translation anchor 的处理。

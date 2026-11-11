## 2026-11-11 | 任务：常驻显示 Codex 高级设置

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-11-codex-advanced-settings.md)、[PR #1391](https://github.com/tisfeng/Easydict/pull/1391)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

Codex 服务的高级设置标题点击无法展开。用户明确要求去掉收起操作，直接显示高级设置。

### 变更

- 将高级设置的 DisclosureGroup 替换为使用原有标题的常驻 Section。
- 保留接入方式、模型、思考强度和所有配置绑定，以及托管和本机 CLI 的条件内容。

### 设计意图

直接展示配置以匹配用户要求。常驻分区使用原有本地化标题，交互入口与配置内容保持直观一致。

### 验证

- 旧版本真机复现：点击高级设置标题无变化；点击小箭头后可以展开。
- `xcodebuild build-for-testing`：成功，SwiftFormat 和 SwiftLint 按项目配置执行。
- 相关 Codex 配置、请求协调、流失效与 DeepSeek OCR 测试：5 个套件共 39 项通过。
- 新版本界面实测与截图：进入 Codex 服务页即显示接入方式、本机模型 gpt-6-luna 和低思考程度，折叠箭头已移除；切换设置标签后返回仍直接显示。
- 验收期间临时显示主窗口，结束时恢复原来的启动后隐藏设置。
- `git diff --check` 通过；语义审查确认修改集中在展示层，原有配置分支与数据绑定保持一致。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/CodexCLIServiceConfigurationView.swift`

### 后续事项

- 本次修改已交付本机版本，后续可按用户要求同步远程 PR。

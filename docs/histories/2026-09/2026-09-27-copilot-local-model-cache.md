## 2026-09-27 | 任务：Copilot 模型选择使用本地目录

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-27-copilot-local-model-cache.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

优化查询窗口选择模型时的等待，只读取本地保存的模型列表；用户通过设置页手动更新并保存最新目录。

### 变更

- 模型目录改为 Codable，缓存模型名称、ID、可用状态、推理能力、刷新时默认模型与更新时间。
- 通过 AppPathManager 定位 `cache/github-copilot/models.json`；共享 Store 首次创建时恢复本地目录，手动刷新先原子保存再发布快照，失败保留旧目录。
- 查询菜单直接读取内存快照，删除异步等待、禁用按钮与目录重试入口；无目录时保留默认和已选模型，显示设置页更新提示。
- 设置页移除打开、展开列表和重新激活时的自动刷新，保留刷新与失败重试按钮，展示上次更新时间。
- 翻译不再查询目录。Runner 先读取 CLI 本地默认模型，再按缓存能力校验推理；不支持或未知能力时省略覆盖参数。
- 保留真实 CLI 错误并增加模型失效时手动更新的提示；更新六种语言、工程注册、本地路径说明及中英文使用指南。

### 设计意图

模型选择只依赖本地数据，CLI 目录请求成为明确的用户操作。缓存不保存凭据、对话或翻译内容；
默认模型在运行请求时读取当前 CLI 配置，避免目录快照改变实际默认模型。继续使用共享 Store
和独立目录通知，刷新不触发翻译；没有旧格式迁移或自动刷新策略。

### 验证

- checkout 专属 Agent DerivedData 的 Debug `xcodebuild build`：通过，仅有 AppIntents metadata extraction 提示。
- 九个修改/新增 Swift 文件的 SwiftFormat lint、项目固定版本 SwiftLint：通过。
- `git diff --check`、工程 `plutil -lint`、String Catalog `jq -e .`：通过。
- 变更的三个本地化 key 均覆盖 en、es、ja、sk、zh-Hans、zh-Hant；Swift/Objective-C 生成接口正确导出菜单提示属性。
- review：以执行前 HEAD 和干净工作树为基线，审查完整任务 diff、新缓存文件、模型订阅、Runner 默认解析及所有刷新入口；无有效 finding。手动刷新与原子快照满足需求，未引入额外兼容层。
- 未新增测试；没有 Copilot 专项现有测试，Xcode Run 正在使用同 bundle ID 调试宿主，未运行 app-hosted tests。菜单点击、重启恢复、磁盘写入失败和实际翻译尚未进行运行时验证。

### 受影响文件

- `Easydict/Swift/Service/GitHubCopilot/` 的模型、目录、Store、Cache、Service 和 Runner。
- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/GitHubCopilotServiceConfigurationView.swift`
- `Easydict/objc/ViewController/View/ResultView/EZResultView.m`
- `Easydict/Swift/Utility/AppPathManager/AppPathManager+Cache.swift`
- `Easydict/App/Localizable.xcstrings`、`Easydict.xcodeproj/project.pbxproj`
- `docs/design-docs/app-path-management.md`、`docs/user-docs/en/GUIDE.md`、`docs/user-docs/zh/GUIDE.md`

### 后续事项

- 新构建首次使用需在设置页手动刷新一次，以建立持久目录；之后可直接选择。
- 调试会话允许时验证菜单点击、重启恢复及刷新失败场景。

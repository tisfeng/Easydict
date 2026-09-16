## 2026-09-17 | 任务：统一应用本地路径与迁移策略

**Links:** [PR #1303](https://github.com/tisfeng/Easydict/pull/1303)、
[设计文档](../../design-docs/app-path-management.md)、提交 `9ed1c0713`、`04c6b7be4`、
`c70dca285`、`8ce6cdbbe`

### 执行上下文

- **Agent Name:** `Codex`
- **Model ID:** `Unknown`

### 用户请求

参考项目现有路径管理方式，新增统一的 `AppPathManager`，按 bundle ID 隔离 Debug 与 Release，
将一般应用本地文件集中到 Application Support，并安全迁移既有 Codex、日志和缓存数据。日志菜单
需要保持原有查看和导出范围，同时补齐该跨模块改动的长期设计与历史记录。

### 变更

- 新增不可变、无副作用的 `AppPathManager` 及 Application Support、旧 Caches 来源和目录准备扩展，
  让 Swift 与 Objective-C 调用方共享 bundle 级路径。
- 将托管 Codex 根目录简化为 `codex`，按实际 bundle ID 隔离 Debug 与 Release，并从旧
  `codex-managed` 位置执行权限和符号链接校验后的原子迁移。
- 将应用日志、OCR 调试图片、音频缓存和 MDict 元数据统一迁入 Application Support；通用迁移
  支持递归合并、相同文件去重和冲突副本保留。
- 将可重新获取或生成的 `cache` 标记为不备份；保留系统临时目录用于短生命周期中转文件。
- 将菜单栏“日志目录”和“导出日志”统一为 `logs/app`；Codex 与 Claude 调用日志保持独立，
  避免普通导出包含 prompt、原文或模型响应。
- 新增路径管理设计文档并接入设计文档与应用架构索引。
- 未新增或修改测试代码。

### 设计意图

Application Support 是 Easydict 自主管理文件的统一根目录，实际 bundle ID 是环境隔离边界，
`AppPathManager` 是路径构造的唯一来源。路径读取本身不创建目录，写入和迁移必须显式处理副作用。

通用日志与缓存数据可以安全合并，因此遇到同名差异项时保留 legacy 副本；Codex 目录包含身份、
配置和运行状态，采用目标优先且不合并的更严格策略。普通日志导出继续只覆盖应用诊断数据，避免
服务调用日志中的用户内容被无提示打包。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug | xcbeautify`：
  通过，包含 Format、Lint、bundled Codex 准备和应用签名验证。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- 代码审查：路径调用链、迁移顺序、日志菜单和导出范围未发现阻塞问题。
- 自动化测试：未运行；本次任务未获授权新增或修改测试代码。

### 受影响文件

- `Easydict/Swift/Utility/AppPathManager/`
- `Easydict/Swift/Service/CodexCLI/CodexDirectoryMigration.swift`
- `Easydict/Swift/Service/CodexCLI/CodexComponentStore.swift`
- `Easydict/Swift/Service/CodexCLI/CodexManagedRuntime.swift`
- `Easydict/Swift/Service/CodexCLI/CodexCLILogger.swift`
- `Easydict/Swift/Service/ClaudeCode/ClaudeCodeLogger.swift`
- `Easydict/Swift/Service/Dictionary/MDict/MDictReader/MDictMetadataCache.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/Model/OCRConstants.swift`
- `Easydict/Swift/View/MenuItemView.swift`
- `Easydict/objc/MMKit/`
- `Easydict/objc/Service/AudioPlayer/EZAudioPlayer.m`
- `Easydict/App/EasydictApp.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/design-docs/app-path-management.md`
- `docs/design-docs/README.md`
- `docs/design-docs/application-architecture.md`

### 后续事项

- 未新增自动化迁移测试；如果需要覆盖中断恢复、同名冲突和符号链接拒绝场景，应在后续任务中
  明确授权新增测试代码。

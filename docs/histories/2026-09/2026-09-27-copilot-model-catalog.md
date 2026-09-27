## 2026-09-27 | 任务：动态加载 Copilot 模型与推理等级

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-27-copilot-model-catalog.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

从本地 CLI 动态取得账号模型及推理能力，删除设置页的模型提示和硬编码名单；功能未发布，不引入旧配置迁移。

### 变更

- 新增短生命周期 JSON-RPC 目录查询，使用 `connect` 与 `models.list`，限制输出大小和查询时间，支持取消并清理临时目录。
- 模型设置改为可搜索选择列表，支持刷新、加载状态、失败重试与选择不可用提示。打开设置及应用重新激活时刷新。
- 推理等级来自所选模型元数据，未知能力、Auto 及不支持调整的模型隐藏该行；不再通过枚举限制服务器返回的新等级。
- 无效推理选择回到默认；显式推理参数在翻译前使用新目录再次校验。取消翻译同时取消查询。
- CLI 默认模型选项只读取已保存的 model 字段，保留临时 home、空工作目录和翻译工具隔离。
- 删除旧提示、占位文案和静态模型名单，更新全部六种语言，注册新增 Swift 文件。
- 仅将 session.error 视为结构化错误，避免 Disabled tools 等 session.info 配置消息遮盖真实错误。

### 设计意图

模型与能力由本机安装的 CLI 及当前账号决定，不依赖应用内的模型快照。查询服务保持独立，翻译仍使用原有流式 CLI 路径；没有引入旧版配置迁移。默认推理不增加元数据查询，显式推理会先查询目录，以避免更新后继续传入不支持的等级。

### 验证

- Debug `xcodebuild build`：成功，使用独立 Agent DerivedData；构建中仅有未链接 AppIntents 的 metadata extraction 提示。
- SwiftFormat、SwiftLint、`git diff --check`、`jq -e .` 和 `plutil -lint`：通过。
- 直接运行生产目录客户端：CLI 1.0.88 返回 16 个模型，Sonnet 5、GPT-6 Luna 的等级不同，Haiku 4.5 与 Auto 无推理覆盖。首轮发现 Auto 缺省能力字段，修正后重跑成功。
- 生产客户端取消查询：返回 CancellationError，子进程结束。
- 生产解析器读取两份用户原始日志：分别保留 minimal/none 对 Sonnet 5 无效的真实错误。
- review：覆盖本任务变更及调用链，复核设置刷新、默认模型、取消、临时目录清理和错误事件过滤，无剩余 finding。直接 RPC 查询满足当前目标，无需将整个翻译路径迁移到 SDK。
- 未新增测试。没有 Copilot 专项既有测试；因 Xcode 正在运行调试宿主，未运行 app-hosted test，尚未完成新界面的实际点击验证。

### 受影响文件

- `Easydict/Swift/Service/GitHubCopilot/` 中的目录客户端、模型、推理标签、环境、Runner、Service 与错误解析。
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/GitHubCopilotServiceConfigurationView.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 首次写入时暂存区已有三项图标配置。本次修改保持未暂存，待明确授权单独提交本任务并保留原暂存内容；未 push。
- 在调试会话允许时验证新设置页的搜索、选择与翻译流程。

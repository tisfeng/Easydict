## 2026-11-17 | 任务：调整「这是什么」的默认使用状态

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-17-adjust-explain-service-default.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2.1 / Xcode 27.2 (27B52)

### 用户请求

将「这是什么」的默认使用状态改为「默认」，处理八条 String Catalog 引用警告，移除指定测试和架构资料。

### 变更

- Explain 单独覆盖使用状态的默认值，继续读取原有偏好键。
- Codex 推理强度通过静态 `LocalizedStringResource` 引用原有译文；移除八个 stale 标记。
- 删除 `ExplainServiceTests.swift`、`aitool-overview.html` 和 `aitool-architecture.svg`，清理 Xcode 引用。

### 设计意图

保留用户已保存的使用状态和其他 AI 工具的默认值。共用可提取的推理强度标签，同时保留托管模式单独的默认选项文案。

### 验证

- `xcodebuild test`（Debug / Default，`CodexServiceTests` 与 `CodexCLIRunnerTests`）：59 个测试通过。
- `git diff --check`、`jq -e .` 与 `plutil -lint`：通过；确认译文不变且工程无删除项引用。
- 手动检查：在本次构建确认未设偏好时，「设置 → 服务 → 这是什么 → 使用状态」显示「默认」，三个选项均可见。截图存于仓库外，恢复了临时偏好。
- 审查：未发现需修复的问题；未发起在线查询。

### 受影响文件

- `Easydict/Swift/Service/AITool/ExplainService.swift`
- `Easydict/Swift/Service/AITool/aitool-overview.html`
- `Easydict/Swift/Service/AITool/aitool-architecture.svg`
- `Easydict/Swift/Service/Codex/Configuration/CodexReasoningEffort.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/CodexCLIServiceConfigurationView.swift`
- `Easydict/App/Localizable.xcstrings`
- `EasydictTests/Service/ExplainServiceTests.swift`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- None

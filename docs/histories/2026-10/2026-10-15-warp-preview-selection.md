## 2026-10-15 | 任务：补充 Warp Preview 强制取词白名单

**Links:** [PR #1343](https://github.com/tisfeng/Easydict/pull/1343)、[Warp 官方文档](https://docs.warp.dev/support-and-community/troubleshooting-and-support/logging-out-and-uninstalling)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

将 Warp Preview 的 bundle ID 加入强制取词白名单。

### 变更

- 在 `.attributeUnsupported` 白名单中新增 `dev.warp.Warp-Preview`。
- 本次为单项低风险配置补充，不创建执行计划或新增测试。

### 设计意图

官方文档确认 Preview 使用独立标识；复用稳定版的复制取词回退路径，继续遵循强制取词开关和应用触发配置。标识已确认，但 Preview 的 AX 错误与运行行为尚未实测。

### 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent-derived-data> -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile EASYDICT_RELEASE_PACKAGING=YES`：通过；使用 agent 专用构建目录，跳过 SwiftFormat 和 SwiftLint。
- 手动检查：仅增加一个 bundle ID，复用现有回退路径；没有现成测试覆盖该白名单行为，未运行交互测试。

### 受影响文件

- `Easydict/Swift/Utility/EventMonitor/Workflow/SelectionWorkflow.swift`
- `docs/histories/2026-10/2026-10-15-warp-preview-selection.md`

### 后续事项

- 在 Warp Preview 中验证实际划词取词和剪贴板恢复。

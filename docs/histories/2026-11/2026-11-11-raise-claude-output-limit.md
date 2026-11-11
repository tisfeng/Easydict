## 2026-11-11 | 任务：提高 Claude 翻译输出上限

**Links:** [Anthropic Messages API](https://platform.claude.com/docs/en/api/messages/create)、[Claude 模型输出上限](https://platform.claude.com/docs/en/models/overview)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2.1 / Xcode 27.2 (27B52)

### 用户请求

将 Claude 翻译请求的输出上限改为 32,000 token，并添加注释。

### 变更

- 将 Claude Messages API 请求中的 `max_tokens` 由 4,096 提高到 32,000。
- 补充英文注释，说明请求需要传入输出上限，以及该值为长译文预留空间。

### 设计意图

使用固定上限，为长文翻译提供更多输出空间，短译文仍可自然结束。

### 验证

- `git diff --check`：通过。
- `xcodebuild test -only-testing:EasydictTests/ClaudeSSEParserTests`：5 项通过。默认签名缺少描述文件，重跑时用临时 ad hoc 签名参数完成本地构建与测试。
- 手动检查：确认请求体的 `max_tokens` 使用更新后的常量。当前 Debug 和正式版偏好均未配置 Claude API Key，长译文在线验收与截图受阻。

### 受影响文件

- `Easydict/Swift/Service/Claude/ClaudeService.swift`

### 后续事项

- 自定义端点需支持 32,000 输出 token。

## YYYY-MM-DD | 任务：<简短动作>

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/agents/README.md 的“Plan 与 History”。 -->

**Links:** <issue、PR、计划或 commit>

### 执行上下文

<!--
- Agent Name：优先填写当前对话上下文明确声明的主执行 agent 名称；不得把客户端、会话 ID 或
  内部角色当作 agent 名称，无法确认时填 Unknown。
- Model：优先填写当前对话上下文明确提供的完整模型 ID；无法取得完整 ID 时，使用上下文明确提供的
  base model。不得根据客户端名称、可用模型列表或命名习惯推测，两者均无法确认时填 Unknown。
- Environment：使用 `sw_vers -productVersion` 和 `xcodebuild -version` 记录当前执行环境；无法取得的值填
  Unknown。执行中切换环境时更新该字段，并在“验证”中说明影响。
-->

- **Agent Name:** `<name or Unknown>`
- **Model:** `<model-id, base-model, or Unknown>`
- **Environment:** `macOS <version or Unknown> / Xcode <version or Unknown> (<build-version or Unknown>)`

### 用户请求

<对请求进行简洁且已脱敏的总结。>

### 变更

- <主要变更>
- <文档或测试变更>

### 设计意图

<说明为什么采用这种方案，以及它保留了哪个边界。>

### 验证

- `<command>`：<结果>
- 手动检查：<结果>

### 受影响文件

- `<path>`

### 后续事项

- <已知限制或下一步；如果没有则填写 `None`>

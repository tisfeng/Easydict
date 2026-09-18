## YYYY-MM-DD | 任务：<简短动作>

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/agents/README.md 的“Plan 与 History”。 -->

**Links:** <issue、PR、计划或 commit>

### 执行上下文

<!--
- Agent Name：填写当前主执行 Agent 的运行上下文明确提供的名称，并原样记录。客户端名称只有在运行上下文
  明确将其声明为当前 Agent 身份时才可使用。不得根据应用名称、进程名、默认配置、会话 ID、内部角色或
  历史记录推测；无法确认时填写 Unknown。
- Model：优先填写当前主执行 turn 的运行上下文或响应元数据明确提供的完整模型 ID，并原样记录。无法取得
  完整 ID 时，依次记录运行上下文明示的模型别名或基础模型。不得根据客户端名称、默认配置、启动参数、
  可用模型列表、模型家族或历史记录推测。以上信息均不可得，或客户端仅显示 Auto 等选择模式时，填写 Unknown。
- Environment：使用 `sw_vers -productVersion` 和 `xcodebuild -version` 记录当前执行环境；无法取得的值填
  Unknown。执行中切换环境时更新该字段，并在“验证”中说明影响。
-->

- **Agent Name:** `<name or Unknown>`
- **Model:** `<model-id, alias, base-model, or Unknown>`
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

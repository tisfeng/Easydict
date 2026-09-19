## 2026-09-18 | 任务：优化模型记录规则

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-18-refine-model-recording.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

优化执行上下文的模型记录规则：优先记录完整模型 ID，无法取得时允许依次使用明确提供的模型别名和基础模型。

### 变更

- 将 Plan 与 History 模板的 `Model ID` 字段改为 `Model`。
- 明确取值顺序为完整模型 ID、模型别名、基础模型、`Unknown`。
- 明确 `Auto` 等选择模式不是模型身份，只有此类信息时填写 `Unknown`。
- 将相同语义同步到 Scoco、boss-resume、EasyKOL Scout 和 skills。

### 设计意图

字段名称覆盖所有允许值，同时继续要求值必须由当前主执行 turn 的运行上下文或响应元数据明确提供。
这既减少能够确认基础模型时不必要的 `Unknown`，也不重新引入根据客户端或历史记录猜测模型的问题。

### 验证

- 模板字段、占位符、取值优先级和 `Auto` 边界检查：通过。
- 四个关联项目的当前模板语义对比：一致。
- 相对链接检查：通过。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

### 受影响文件

- `docs/exec-plans/templates.md`
- `docs/histories/template.md`
- `docs/exec-plans/completed/2026-09/2026-09-18-refine-model-recording.md`
- `docs/histories/2026-09/2026-09-18-refine-model-recording.md`

### 后续事项

- None

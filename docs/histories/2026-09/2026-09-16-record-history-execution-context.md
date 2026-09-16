## 2026-09-16 | 任务：约束 History 执行上下文

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model ID:** `Unknown`

### 用户请求

参考 `open-codex-computer-use` 的 history 记录，为 Easydict 模板增加执行上下文，并解决既有
`Agent ID`、`Base Model` 和 `Runtime` 含义混乱、取值不准确的问题。

### 变更

- 增加 `Agent Name`，只记录主执行 agent 的明确名称。
- 增加 `Model ID`，要求使用当前任务明确提供的完整模型标识，无法确认时填写 `Unknown`。
- 不引入 `Runtime`；环境信息仅在影响结果时写入验证记录。

### 设计意图

将 agent、模型和执行环境分开，避免把客户端或系统架构误写成 agent 或 runtime，也避免用
`GPT-5` 等模型族名称替代实际模型标识。

### 验证

- `git diff --check`：通过。
- 手动检查：模板仅保留两个必填字段，限制描述简短且未引入 `Runtime`。

### 受影响文件

- `docs/histories/template.md`
- `docs/histories/2026-09/2026-09-16-record-history-execution-context.md`

### 后续事项

- None

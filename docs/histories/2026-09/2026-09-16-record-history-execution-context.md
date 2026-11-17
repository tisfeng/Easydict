## 2026-09-16 | 任务：约束 History 执行上下文

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `gpt-5.6-sol`

### 用户请求

参考 `open-codex-computer-use` 的 history 记录，为 Easydict 模板增加执行上下文，并解决既有
`Agent ID`、`Base Model` 和 `Runtime` 含义混乱、取值不准确的问题。

### 变更

- 增加 `Agent Name`，只记录主执行 agent 的明确名称。
- 增加 `Model`，优先记录对话上下文明确提供的完整模型 ID，无法取得时允许使用明确的 base model，
  两者均无法确认时填写 `Unknown`。
- 不引入 `Runtime`；环境信息仅在影响结果时写入验证记录。

### 设计意图

将 agent、模型和执行环境分开，避免把客户端或系统架构误写成 agent 或 runtime。模型信息以
对话上下文为通用来源，不依赖特定客户端字段或本地存储格式；可取得完整 ID 时记录完整 ID，
否则保留明确的 base model。

### 验证

- `git diff --check`：通过。
- 手动检查：模板仅保留两个必填字段，支持完整模型 ID、base model 和 `Unknown`，且未引入
  `Runtime`。

### 受影响文件

- `docs/histories/template.md`
- `docs/histories/2026-09/2026-09-16-record-history-execution-context.md`

### 后续事项

- None

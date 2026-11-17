## 2026-09-15 | 任务：允许文档 slug 保留稳定标识格式

**Links:** None

### 用户请求

将 Plan 与 History 文件名规则同步到 Easydict，允许版本号等稳定标识保留标准格式。

### 变更

- 明确 slug 的描述性部分仍使用小写 kebab-case，但版本号等稳定标识可以保留点号。
- 将 Plan 与 History 模板中的重复规则改为指向统一的 Agent 文档权威来源。

### 设计意图

保留 `v0.3.8`、`0.1.1` 等版本标识的标准写法和可追踪性，同时限制例外范围，避免任意标点进入
文件名或削弱普通描述部分的 kebab-case 约束。

### 验证

- `git diff --check`：通过。
- 命名规则与现有文件名静态检查：通过。

### 受影响文件

- `docs/agents/README.md`
- `docs/exec-plans/templates.md`
- `docs/histories/template.md`
- `docs/histories/2026-09/2026-09-15-allow-stable-identifiers-in-document-slugs.md`

### 后续事项

- None

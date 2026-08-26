## 2026-08-23 | 任务：统一计划与历史文档结构标题

**Links:** `docs/exec-plans/`、`docs/histories/`

### 用户请求

将 `histories` 和 `exec-plans` 的结构性子标题统一为中文。

### 变更

- 将计划和历史模板及现有文档的结构性标题统一为中文。
- 保留正文语义、技术名词、引用路径和文件名不变。

### 设计意图

让中文计划和历史文档使用一致的结构标题。

### 验证

- 标题检查：未发现旧的英文结构性标题。
- `git diff --check`：通过。

### 受影响文件

- `docs/exec-plans/templates.md`
- `docs/exec-plans/completed/`
- `docs/histories/README.md`
- `docs/histories/template.md`
- `docs/histories/2026-08/`

### 后续事项

- None

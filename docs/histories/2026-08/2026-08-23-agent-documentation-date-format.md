## 2026-08-23 | 任务：统一 Agent 计划与历史文档日期文件名

**Links:** `docs/exec-plans/`、`docs/histories/`

### 用户请求

统一执行计划和变更历史文件名中的日期格式，使用 `YYYY-MM-DD`。

### 变更

- 将计划和历史任务文件统一命名为 `YYYY-MM-DD-<slug>.md`。
- 在计划、历史 README 和模板中明确文件名规则。
- 更新重命名后残留的文档路径引用。

### 设计意图

让目录日期、文件名日期和文档标题中的日期使用同一种可读格式，同时保留
`docs/histories/YYYY-MM/` 月份归档结构和长期迁移路线图的无日期文件名。

### 验证

- 文件名检查：全部任务文档均符合 `YYYY-MM-DD-<slug>.md`。
- 旧文件名引用检查：未发现 `YYYYMMDD-*` 文件名引用。
- `git diff --check`：通过。
- 尾随空白检查：通过。

### 受影响文件

- `docs/exec-plans/README.md`
- `docs/exec-plans/templates.md`
- `docs/histories/README.md`
- `docs/histories/template.md`
- `docs/exec-plans/completed/`
- `docs/histories/2026-08/`

### 后续事项

- None

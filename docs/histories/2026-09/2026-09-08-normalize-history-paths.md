# 2026-09-08 | 任务：规范历史记录路径

### 用户请求

检查并修复 `docs/histories/` 顶层未按月份归档的历史记录。

### 变更

- 将两份 2026-08 的顶层历史记录归档到 `docs/histories/2026-08/`。
- 同步修正移动后受影响的执行计划链接和历史记录自引用路径。
- 补全一份 2026-08 历史记录文件名中缺失的日期分隔符。

### 设计意图

保持历史记录符合 `YYYY-MM/YYYY-MM-DD-<slug>.md` 目录和命名约定，同时保留原有内容及
Git 历史可追踪性。

### 验证

- `git diff --check`：通过。
- 静态检查：顶层仅保留 `README.md` 和 `template.md`，月份目录中的目标文件名符合约定，
  相对链接目标存在。

### 受影响文件

- `docs/histories/2026-08/2026-08-25-agent-rule-structure-port.md`
- `docs/histories/2026-08/2026-08-27-generic-planner-agent.md`
- `docs/histories/2026-08/2026-08-31-planner-latency-description.md`
- `docs/histories/2026-09/2026-09-08-normalize-history-paths.md`

### 后续事项

- None

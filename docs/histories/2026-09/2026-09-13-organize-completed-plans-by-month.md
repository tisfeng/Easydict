## 2026-09-13 | 任务：按月份归档已完成执行计划

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-13-organize-completed-plans-by-month.md)

### 用户请求

使 `docs/exec-plans/completed/` 与 histories 一样按月份组织，同时保留 active 计划的扁平结构。

### 变更

- 将 58 份既有 completed plan 按文件名月份移入 `2026-08/` 和 `2026-09/`。
- 更新计划生命周期规则、目录说明、模板归档路径及仓库内相关引用。
- 本任务计划归档后，completed 月份目录共保存 59 份计划。

### 设计意图

月份目录直接取计划文件名的 `YYYY-MM` 前缀，保留文件名和历史内容；`active/` 继续扁平展示当前工作，只有完成归档时增加月份层级。

### 验证

- 数量与月份检查：58 份既有计划全部进入匹配目录，completed 根层无 Markdown 文件。
- 内容检查：计划和引用文档除必要路径适配外无其他变化。
- 本地 Markdown 链接检查：53 个链接均有效。
- 旧路径搜索：没有残留的 `completed/YYYY-MM-DD-<slug>.md` 引用。
- `git diff --check`：通过。
- Xcode 构建与测试：未运行；本次仅调整治理 Markdown。

### 受影响文件

- `docs/agents/README.md`
- `docs/exec-plans/README.md`
- `docs/exec-plans/templates.md`
- `docs/exec-plans/completed/YYYY-MM/`
- 引用 completed plan 的 history 和计划文档

### 后续事项

- None

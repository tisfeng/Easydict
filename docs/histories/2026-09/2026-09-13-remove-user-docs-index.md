## 2026-09-13 | 任务：删除公共文档目录索引

**Links:** None

### 用户请求

删除 `docs/user-docs/README.md`，并清理实际使用它的现行文档入口。

### 变更

- 删除中英文公共文档的汇总索引文件。
- 移除根中英文 README 中指向该索引的两条链接，保留各专题文档的直接入口。

### 设计意图

根 README 已分别列出完整指南、服务总览和专题文档，不再维护功能重复的中间导航页。已完成
计划和 history 中的旧路径仍作为历史事实保留。

### 验证

- 非历史文档中的索引路径残留检查：通过。
- Markdown 相对链接与锚点检查：通过。
- `git diff --check`：通过。

### 受影响文件

- `README.md`
- `README_ZH.md`
- `docs/user-docs/README.md`
- `docs/histories/2026-09/2026-09-13-remove-user-docs-index.md`

### 后续事项

- None

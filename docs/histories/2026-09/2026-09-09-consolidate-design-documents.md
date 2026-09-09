## 2026-09-09 | 任务：统一设计文档目录并移除冗余 Skill 别名

**Links:** [执行计划](../../exec-plans/completed/2026-09-09-consolidate-design-documents.md)

### 用户请求

将相近的 `docs/architecture/` 和 `docs/design-docs/` 统一到更通用的
`docs/design-docs/`，并删除指向真实 `.agents/skills/` 内容的根 Skill 兼容链接。

### 变更

- 将应用架构与文本选择流程迁入 `docs/design-docs/`，删除原 `docs/architecture/` 索引，
  并将统一目录按“产品与技术设计”和“Agent 与仓库治理”分组。
- 精简两篇 Agent 治理设计，保留长期背景、设计决策、取舍和重新评估条件；现行操作条款继续
  链接 `docs/agents/` 中的唯一权威来源。
- 更新根 Agent 路由、贡献指南、Agent 文档分层、公共文档索引和 Swift 迁移计划中的现行
  链接。
- 删除根 `skills/fireworks-tech-graph` 兼容符号链接；保留真实 `.agents/skills/` 内容、
  `.claude/skills` 兼容入口和双 lock，并在 reference 中区分上游路径与本地安装路径。

### 设计意图

减少顶层文档分类和重复索引，同时保持实现说明、长期设计决策、现行规则和历史记录的职责
边界；Skill 只保留一份真实安装内容。

### 验证

- `git diff --check` 通过。
- 41 个现行本地 Markdown 链接均可解析；旧架构路径只在本记录和执行计划中作为迁移事实出现。
- 真实 `fireworks-tech-graph` Skill 与 `.claude/skills` 可解析，受管资产和双 lock 无差异。
- 独立 reviewer 发现的任务约束语义冲突已修正，最终增量复审无新增 finding。
- 变更不涉及产品代码或 Xcode 工程，因此未运行构建或测试。

### 受影响文件

- `AGENTS.md`、`CONTRIBUTING.md`、`docs/agents/README.md`
- `docs/design-docs/`、原 `docs/architecture/`
- `docs/references/fireworks-tech-graph.md`、`docs/user-docs/README.md`
- `docs/exec-plans/active/swift-migration.md`、本任务 plan/history
- `skills/fireworks-tech-graph`

### 后续事项

- 无。后续只有在上游 Skill 来源或安装目录发生变化时，才按 reference 的重新核对条件更新。

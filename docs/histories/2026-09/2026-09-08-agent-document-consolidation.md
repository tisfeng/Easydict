## 2026-09-08 | 任务：收敛 Agent 文档结构

**Links:** [执行计划](../../exec-plans/completed/2026-09-08-agent-document-consolidation.md)

### 用户请求

合并重复且过度拆分的 Agent 文档，保留清晰的唯一入口和必要安全边界；职责内聚的文档
只要不超过 500 行，就不因较低行数阈值继续拆分。

### 变更

- 将根 `AGENTS.md` 收敛为通用约束和唯一任务路由，将回复表达压缩到根入口。
- 将 `execution-safety.md` 并入 `request-boundary.md`，形成请求、Mutation Gate、protected
  和子代理边界的单一权威来源。
- 将跨语言代码质量、Swift/Xcode 和本地化规则合并为 `development.md`；构建与测试继续
  独立维护验证策略和命令。
- 将外部 Agent 资产和双 lock 治理并入 `docs/agents/README.md`，删除六份被合并文档。
- 精简 `git-workflow.md` 对受管 `git-delivery` 内部算法的复述，同时保持显式 staged、
  自动提交和 integration 的不同集合关系。
- 更新贡献指南、Agent 文档结构设计和外部资产设计中的活动链接。

### 设计意图

通过“根入口 + 专题权威文件”减少重复路由和维护漂移，同时保持请求授权、工作树保护、
Git 交付、验证和外部受管资产边界不变。

根入口和五份专题规则共 511 行，单文件最高 108 行。职责内聚的专题只要不超过约 500 行，
不再为了较低行数阈值拆分。

### 验证

- `git diff --check` 和 11 个变更 Markdown 的相对文件链接检查通过，新锚点存在。
- 被删除规则文件在现行入口和活动文档中没有残留引用；历史计划和 history 未批量改写。
- 11 个请求、授权、Git、PR、同步和失败场景检查通过。
- 独立 reviewer 的两项 Git 集合关系 finding 已修复；增量复审无新增 finding。
- 受管 agents、双 lock、Skills、产品源码和 Xcode 工程均未修改。
- 未运行 Xcode，因为本次只有治理 Markdown；未执行实际 GUI 或远程行为验证。

### 受影响文件

- `AGENTS.md`
- `CONTRIBUTING.md`
- `docs/agents/`
- `docs/design-docs/agent-documentation-structure.md`
- `docs/design-docs/external-agent-assets-management.md`
- `docs/exec-plans/completed/2026-09-08-agent-document-consolidation.md`

### 后续事项

- 无。

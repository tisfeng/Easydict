## 2026-09-13 | 任务：简化 Agent 文档与任务模式

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-13-simplify-agent-docs.md)

### 用户请求

删除 Agent 文档中对通用 Skill 的重复说明，移除多余的 Review 和维护约束，并把复杂的请求边界与
Git 交付规则合并为只区分计划模式和执行模式的简洁文档。

### 变更

- 新增 `docs/agents/task-modes.md`，规定计划模式只输出方案、不修改项目；执行模式完成修改与验证后
  自动创建本地提交，外部交付仍需明确授权。
- 删除 `docs/agents/request-boundary.md` 和 `docs/agents/git-delivery.md`，同步精简 `AGENTS.md`、
  Agent 治理文档、构建规则、执行计划模板和相关参考资料。
- 移除通用 Skill 路由与工作流细节，只保留 Easydict 的项目默认值、Xcode 规则、文档生命周期和
  外部 Skill 资产治理边界。

### 设计意图

让项目文档只维护项目特有规则，通用 Skill 的执行契约由 Skill 自身维护。计划与执行的授权边界
集中在一份短文档中，减少重复、冲突和阅读成本。

### 验证

- 旧文件名、Mutation Gate、旧状态字段与通用 Skill 路由检索：无残留。
- Markdown 相对链接与锚点检查：10 项通过。
- `git diff --check`：通过。
- 手动检查：`AGENTS.md` 从 68 行缩减为 33 行，`docs/agents/` 从 480 行缩减为 280 行。
- `xcodebuild`：未运行；本任务只修改不进入 Xcode 构建图的治理 Markdown。

### 受影响文件

- `AGENTS.md`
- `docs/agents/`
- `docs/exec-plans/README.md`
- `docs/exec-plans/templates.md`
- `docs/exec-plans/completed/2026-09/2026-09-13-simplify-agent-docs.md`
- `docs/histories/README.md`
- `docs/histories/2026-09/2026-09-13-simplify-agent-docs.md`
- `docs/references/astra-agent-guidance.md`
- `docs/references/easydict-agent-documentation-port.md`

### 后续事项

- None

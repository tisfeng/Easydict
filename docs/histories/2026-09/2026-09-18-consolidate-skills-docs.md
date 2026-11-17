## 2026-09-18 | 任务：Skill 文档整合为单一 skills.md

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-18-consolidate-skills-docs.md)

### 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-individual-coding-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

Skill 文档散落在 `skills.md`、`external-agent-assets-management.md`、`tisfeng-skills.md`
等多处且过于啰嗦（不需要记录每个版本升级的变动），要求简化集中为一个文档管理。

### 变更

- 重写 `docs/agents/skills.md` 为唯一 Skill 管理文档：背景与设计（合并治理设计文档）、
  操作规则、来源基线 `tisfeng/skills` 与 `fireworks-tech-graph` 四章。
- 删除 `docs/references/tisfeng-skills.md`、`docs/references/fireworks-tech-graph.md` 和
  `docs/design-docs/external-agent-assets-management.md`。
- `docs/references/README.md` 收窄为纯外部证据索引；`docs/design-docs/README.md` 删除
  「Agent 与仓库治理」章节；`AGENTS.md` 路由行改为「参考资料与外部证据」。
- 删除版本升级流水账（v0.3.5–v0.6.0 逐版变动）、Codex 子代理移除叙事和日期化验证日志；
  保留当前基线数据（版本、commit、安装命令）和持久注意事项。

### 设计意图

Skill 管理单一来源化：规则、设计理由和来源基线同置一个文档，`references/` 只保留纯外部
证据，符合「参考资料只提供证据不定义规则」的分层。基线数据与 lock 一致，过程记录由
histories 承载，参考文档不复制。

### 验证

- 全库链接与锚点校验（`docs/` 全部 Markdown 与 `AGENTS.md`，116 个链接）：零失败。
- 覆盖核对：16 项持久条款与基线数据在新文档全部命中，版本流水账未残留。
- review：1 个 P3 finding（丢失「不维护根 `skills/` 兼容别名」边界）已修复并增量复验。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

### 受影响文件

- `AGENTS.md`
- `docs/agents/skills.md`
- `docs/design-docs/README.md`
- `docs/design-docs/external-agent-assets-management.md`（删除）
- `docs/exec-plans/completed/2026-09/2026-09-18-consolidate-skills-docs.md`
- `docs/histories/2026-09/2026-09-18-consolidate-skills-docs.md`
- `docs/references/README.md`
- `docs/references/fireworks-tech-graph.md`（删除）
- `docs/references/tisfeng-skills.md`（删除）

### 后续事项

- None

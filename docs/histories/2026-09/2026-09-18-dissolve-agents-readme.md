## 2026-09-18 | 任务：拆分移除 docs/agents/README.md

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-18-dissolve-agents-readme.md)

### 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-individual-coding-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

拆分移除 `docs/agents/README.md`：与 `AGENTS.md` 重复的规则描述删除，Plan 与 History 规则
下沉到对应目录 README，外部 Skill 资产规则新建 `docs/agents/skills.md` 承载。

### 变更

- 重写 `docs/histories/README.md`（吸收 history 规则与共享命名/slug）和
  `docs/exec-plans/README.md`（吸收 plan 规则），新建 `docs/agents/skills.md`，删除
  `docs/agents/README.md`。
- `AGENTS.md` 执行前改为链接两个目录 README，任务路由拆为计划/history、参考资料、外部
  Skills 三条，通用规则吸收单一职责、相对仓库路径和历史材料约束三项。
- `docs/design-docs/external-agent-assets-management.md` 治理规则指针翻转到 `skills.md`；
  两个模板的命名注释指向 `histories/README.md`。
- 修复 `2026-09-18-agents-md-links.md` 中 `../../AGENTS.md` 死链；档案中的 `agents/README`
  引用均为正文而非链接，按只动链接原则无需改动。

### 设计意图

规则就近下沉到被治理产物的目录 README，保持「现行规则在 `docs/agents/`、设计理由在
`design-docs/`」分层；共享命名规则只保留在 `histories/README.md` 一处，其他位置用链接
引用。删除条款均为已确认重复（`AGENTS.md` 原文、执行模式步骤或 `build-and-test.md`
对应条款）。

### 验证

- 全库链接与锚点校验（`docs/` 全部 Markdown 与 `AGENTS.md`，120 个链接）：零失败。
- 覆盖核对：原 README 各章节关键条款在新位置全部命中。
- review：2 个 P3 finding（共享 slug 条款复述、换行断词）已修复并增量复验。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

### 受影响文件

- `AGENTS.md`
- `docs/agents/README.md`（删除）
- `docs/agents/skills.md`（新增）
- `docs/design-docs/external-agent-assets-management.md`
- `docs/exec-plans/README.md`
- `docs/exec-plans/completed/2026-09/2026-09-18-dissolve-agents-readme.md`
- `docs/exec-plans/templates.md`
- `docs/histories/README.md`
- `docs/histories/2026-09/2026-09-18-agents-md-links.md`
- `docs/histories/2026-09/2026-09-18-dissolve-agents-readme.md`
- `docs/histories/template.md`

### 后续事项

- None

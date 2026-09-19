## 2026-09-18 | 任务：同步 Agent 文档重构到三个关联仓库

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-18-sync-agent-docs-refactor.md)

### 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-individual-coding-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将 Easydict 最近的 agent 文档修改（链接化、拆分 agents/README、Skill 文档整合、排版统一）
同步移植到 Scoco、skills 和 easykol-scout-extension。

### 变更

- Scoco（commit `8eca226fe`）：新建 skills.md（含 v0.6.1 基线、release-scoco/sync-agent-docs
  专属边界和应用内置 Agent 文档边界章节），删除 agents/README 与三个旧文档，plan/history
  规则下沉，AGENTS.md 链接化，backend 契约文档权威指针改指 skills.md。
- easykol-scout-extension（commit `3ebabbcc9`）：同构移植（v0.6.0 基线、WXT/MV3 宿主政策、
  fireworks 先核对 main 规则），公共文档路径一并链接化，既有超宽行换行。
- skills（commit `65f0d49e8`）：Plan 与 History 规则下沉并保留本仓库特有条款，Skill 源码与
  发现独立为 skills.md，「不进入安装载荷」迁入 build-and-test.md，修正四个档案既有死链。
- 三个仓库各自创建同 slug plan 与 history 并创建本地提交；本仓库仅新增本计划与 history。

### 设计意图

移植按「结构同构、数据各异」执行：目录布局与规则语义与 Easydict 一致，基线版本、专属
Skill、宿主政策使用各仓库现行文档的数据；过程记录（版本流水账、日期化日志）一律不移植，
由各仓库 histories 承载。

### 验证

- Scoco：101 个链接与锚点零失败，19 项持久条款覆盖命中，`git diff --check` 通过。
- easykol-scout-extension：112 个链接与锚点零失败，覆盖核对通过，`git diff --check` 通过。
- skills：73 个链接与锚点零失败，覆盖核对通过，`git diff --check` 通过。
- 各仓库治理文档正文 ≤100 显示列（模板 Environment 占位符行除外）。
- `xcodebuild`：未运行；全部变更仅为治理 Markdown。

### 受影响文件

- `docs/exec-plans/completed/2026-09/2026-09-18-sync-agent-docs-refactor.md`
- `docs/histories/2026-09/2026-09-18-sync-agent-docs-refactor.md`
- 关联仓库各 13–16 个治理 Markdown（见各仓库 history 记录）

### 后续事项

- None

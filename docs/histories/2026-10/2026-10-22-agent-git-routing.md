## 2026-10-22 | 任务：统一 Agent 与贡献指南的分支命名引用

**Links:** [Agent 任务入口](../../../AGENTS.md#任务路由)、[分支命名规范](../../../.agents/skills/git-commit/references/branch-naming.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

AGENTS.md 与 CONTRIBUTING.md 统一引用 git-commit 分支命名规则，澄清 PR 来源分支要求。

### 变更

- AGENTS.md 直接路由到 git-commit 的分支命名规范，不再间接引用 CONTRIBUTING.md。
- CONTRIBUTING.md 引用同一规范，移除本地重复的命名格式与示例。
- 独立任务分支要求仅适用于 PR 来源分支，不限制日常本地提交。

### 设计意图

使 Agent 与贡献者使用同一命名入口，避免规则分散以及将 PR 约定扩大到普通本地提交。
本次为简单文档变更，不创建独立执行计划。

### 验证

- `git diff --check`：通过。
- 相对链接及锚点检查：通过。
- 手动检查：两个入口均引用已存在的命名文档，没有复制规则或修改受管 Skill；纯文档变更不运行构建或测试。

### 受影响文件

- `AGENTS.md`
- `CONTRIBUTING.md`
- `docs/histories/2026-10/2026-10-22-agent-git-routing.md`

### 后续事项

- None

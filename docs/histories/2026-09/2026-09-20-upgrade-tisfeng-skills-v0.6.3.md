## 2026-09-20 | 任务：升级 `tisfeng/skills` 至 v0.6.3

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-20-upgrade-tisfeng-skills-v0.6.3.md)、[上游 Release](https://github.com/tisfeng/skills/releases/tag/v0.6.3)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将 Easydict 使用的六个 `tisfeng/skills` 依赖升级到 v0.6.3，并单独创建本地提交。

### 变更

- 用 `skills@1.5.25` 将六个外部受管 Skill 和 `skills-lock.json` 从 v0.6.2 升级到 v0.6.3。
- 同步 `git-commit` 的双语标题语言一致性契约，并更新来源基线到 annotated tag
  `b3f23c01fea0bfd7457301e1b524e0d0cbd2a54c` 和 peeled commit
  `a49a909bdf1b19db281f212e32cd1f3af0b54c30`。
- 保留 `fireworks-tech-graph` 与 `release-easydict` 不变。

### 设计意图

固定正式 tag 并保存完整快照，使依赖可离线审查和复现；不把项目专属 Skill 与独立第三方来源
混入统一升级。

### 验证

- 六个目录逐文件匹配 v0.6.3 tag tree，独立重算的 SHA-256 全部匹配 lock 和上游来源。
- `git-commit` 19 项现有测试、Python compile、lock JSON、Skill YAML 和 `git diff --check` 通过。
- 保护路径与 `.claude/skills` 链接未变化；本地 review 无 P0-P3 finding。
- 未运行 Xcode 构建或测试；本次差异不进入 Xcode 构建图。

### 受影响文件

- `.agents/skills/git-commit/`
- `skills-lock.json`
- `docs/agents/skills.md`
- 本任务 plan/history

### 后续事项

- None

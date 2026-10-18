## 2026-09-20 | 任务：升级 `tisfeng/skills` 至 v0.6.2

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-20-upgrade-tisfeng-skills-v0.6.2.md)、[上游 Release](https://github.com/tisfeng/skills/releases/tag/v0.6.2)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

更新 Easydict 使用的 `tisfeng/skills` 依赖；SelectedTextKit 不在本次范围内。

### 变更

- 用 `skills@1.5.25` 将六个外部受管 Skill 和 `skills-lock.json` 从 v0.6.1 升级到 v0.6.2。
- 更新来源基线到 annotated tag `b30ebbc0599fbf29bb563052b119de5967bd10a8` 和 peeled commit `ee30f149f523a76b14df55884fe149a549798d2f`。
- 保留 `fireworks-tech-graph` 与 `release-easydict` 不变。

### 设计意图

固定已发布 tag 并保存完整快照，保持项目可离线审查和复现；不把项目专属 Skill 与独立第三方来源混入统一升级。

### 验证

- 六个受管目录和 lock ref 与 v0.6.2 一致；变更集中于 `review-pr` 及 lock。
- `jq -e . skills-lock.json`、`git diff --check` 通过；保护路径未修改。

### 受影响文件

- `.agents/skills/review-pr/`
- `skills-lock.json`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-09/2026-09-20-upgrade-tisfeng-skills-v0.6.2.md`

### 后续事项

- None

## 2026-09-13 | 任务：升级受管 Skills 至 v0.4.0

**Links:** https://github.com/tisfeng/skills/releases/tag/v0.4.0

### 用户请求

将 Easydict 依赖的 `tisfeng/skills` 受管快照更新到最新稳定发布。

### 变更

- 使用 `skills@1.5.25` 将六个受管 Skill 从 `v0.3.9` 同步至 `v0.4.0`，并更新目录 hash 和 lock。
- 引入统一 UI 元数据、精简后的触发描述和根入口，以及按需读取的工作流 references。
- 同步上游精简后的高价值测试集合，并更新来源、版本、命令和本地验证记录。

### 设计意图

继续以固定 annotated tag 和完整 Skill 目录作为离线快照，采用上游的渐进式披露优化而不维护
项目内分叉。独立来源 `fireworks-tech-graph` 与项目专属 `release-easydict` 保持不变。

### 验证

- 上游：`v0.4.0` annotated、unsigned，peeled commit 为
  `5c112937e098b14f0d3d63dc4e4691e541c48c88`。
- 安装器：六个目标 Skill 均成功以 `--copy --full-depth` 同步。
- 目录 hash：六个受管 Skill 与 `skills-lock.json` 全部一致。
- Python 3.12：`git-commit` 13 项、`review` 7 项、`review-pr` 45 项、`submit-pr` 15 项、
  `worktree-rebase-merge` 6 项，共 86 项通过。
- 静态检查：frontmatter、`agents/openai.yaml`、相对链接、JSON 和 `git diff --check` 通过。

### 受影响文件

- `.agents/skills/code-simplifier/`
- `.agents/skills/git-commit/`
- `.agents/skills/review/`
- `.agents/skills/review-pr/`
- `.agents/skills/submit-pr/`
- `.agents/skills/worktree-rebase-merge/`
- `skills-lock.json`
- `docs/references/tisfeng-skills.md`
- `docs/histories/2026-09/2026-09-13-upgrade-managed-skills-v0-4-0.md`

### 后续事项

- None

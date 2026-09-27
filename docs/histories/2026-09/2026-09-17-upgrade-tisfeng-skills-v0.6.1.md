## 2026-09-17 | 任务：升级 `tisfeng/skills` 至 v0.6.1

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-17-upgrade-tisfeng-skills-v0.6.1.md)、[上游 Release](https://github.com/tisfeng/skills/releases/tag/v0.6.1)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`

### 用户请求

更新 Easydict 项目依赖的上游 Skills。

### 变更

- 用 `skills@1.5.25` 将六个受管目录和 lock ref 从 `v0.6.0` 升级到 `v0.6.1`。
- 同步 `review-pr` 的本人 PR 同名分支安全复用能力，并更新对应文档、脚本与现有测试。
- 同步 `worktree-rebase-merge` 不含斜杠的 UI 展示名称，并更新来源证据。

### 设计意图

继续固定正式 annotated tag 并保存完整上游快照，使依赖可离线审查和复现；仅覆盖 lock 声明的
六个 `tisfeng/skills` 目录，保留独立来源与项目专属 Skill。

### 验证

- 六个受管目录与 `v0.6.1` tag 逐文件一致；七个 lock 目录的独立 SHA-256 重算全部匹配。
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .agents/skills/review-pr/tests -p 'test_*.py'`：53 项通过。
- `bash -n`、Python `compileall`、两个变更 Skill 的 `quick_validate.py`、YAML/JSON 解析与
  `git diff --check`：通过。
- 本地 `review`：未发现有效 finding。

### 受影响文件

- `.agents/skills/review-pr/`
- `.agents/skills/worktree-rebase-merge/agents/openai.yaml`
- `skills-lock.json`
- `docs/references/tisfeng-skills.md`
- `docs/exec-plans/completed/2026-09/2026-09-17-upgrade-tisfeng-skills-v0.6.1.md`
- `docs/histories/2026-09/2026-09-17-upgrade-tisfeng-skills-v0.6.1.md`

### 后续事项

- None

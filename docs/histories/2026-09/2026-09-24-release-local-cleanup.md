## 2026-09-24 | 任务：完成发布后清理本地临时文件

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-24-release-local-cleanup.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

改进 `release-easydict`，在发布和 Issue 跟进完成后清理该版本无用的 `.tmp` 文件；现有历史版本仅检查，不立即删除。

### 变更

- 增加 `cleanup <version> [--execute]`：检查成功 ASC Publish、已执行 Issue 计划、活动运行、构建锁及 Git worktree，然后预览或删除该版本产物、状态、日志和匹配 ASC 运行记录。
- 清理中断时保留暂时收据，以便安全重试；缓存和其他版本数据不受影响。
- 更新 Skill 与发布文档，在 Publish/Release 和 Issue resume 的最终报告保存后执行清理。

### 设计意图

Issue 跟进不属于 ASC Publish workflow，所以清理放在 Skill 的最后阶段。保留 `.tmp/release/cache/` 供未来版本复用，避免删除未确认失效的 fingerprint。

### 验证

- `bash -n`、`python3 -m py_compile`、`git diff --check`：通过。
- 2.22.0、2.23.0：仅预览，分别估算 15.81 GiB、8.40 GiB，未删除。
- 隔离 Git 仓库：未完成、脏 worktree、新运行拦截，清理、缓存保留和失败重试均通过。
- 现有 release unittest：80 项中 79 项通过；一项未修改的构建锁测试在临时目录清理时报 `Directory not empty`。
- Xcode 构建未运行；没有修改 App 构建图。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/issue-followup.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `.agents/skills/release-easydict/scripts/release-cleanup.py`
- `.agents/skills/release-easydict/scripts/release-easydict.sh`
- `docs/releases/easydict.md`
- `docs/exec-plans/completed/2026-09/2026-09-24-release-local-cleanup.md`
- `docs/histories/2026-09/2026-09-24-release-local-cleanup.md`

### 后续事项

- 2.22.0 和 2.23.0 的历史数据需另行明确执行清理；本次未删除。

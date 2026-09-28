## 2026-09-20 | 任务：同步发布日志到 dev 和本地分支

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-20-release-notes-sync-dev-local.md)

### 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

改进 `sync-notes`：同步已发布版本日志时，同时更新远程 `dev` 和本地 Git，而不是只更新远程 `main`。

### 变更

- 将 appcast 同步从 GitHub Contents API 单分支写入改为临时 worktree 中的 Git 提交。
- Preview 同时读取远程 `main`/`dev`、分支 head、appcast blob 和本地 `main`/`dev` 状态。
- Execute 使用远程 branch head 与 `git push --atomic`、`--force-with-lease` 同时推进远程
  `main`/`dev`，并安全 fast-forward 本地分支。
- 保留 Release ETag；目标 appcast 只允许修改对应版本的 `<description>`，最终验证两个远程分支
  和 GitHub Release body。
- 按用户要求直接移除内部 CLI 的 `--appcast-branch` 参数，固定同步 `main`、`dev` 和本地分支。
- 更新 Skill、发布 reference、公开发布指南、focused tests 和路由测试。

### 设计意图

使用 Git 提交和双分支原子推送，使发布日志修订具有可审查的历史，并避免只更新 `main` 导致本地
和 `dev` 分支漂移。执行过程不重建 App、不修改 Tag/附件/版本号/构建号/渠道，也不改变 `resume`、
`draft` 或正常 `publish` 语义。

### 验证

- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：首次运行
  在测试断言后清理临时 Git 目录时遇到目录非空；仅对测试进程禁用 Git 自动 maintenance/gc
  后重跑，71 项全部通过，未修改仓库配置。
- `test_release_notes_sync.py` 和 `test_release_redraft.py`：相关 12 项测试通过。
- `python3 -m py_compile .agents/skills/release-easydict/scripts/release-notes-sync.py`：通过。
- `bash -n .agents/skills/release-easydict/scripts/release-easydict.sh`：通过。
- `git diff --check`：通过。
- `./.agents/skills/release-easydict/scripts/release-easydict.sh sync-notes 2.23.0`：preview 成功，显示远程 `main`/`dev`
  内容一致，本地 `main` 需要更新；未执行远程写入。
- Review：收紧 origin GitHub 主机校验，并修正迁移后公开指南未披露远程 `dev` 和本地分支写入
  的描述；复核未发现需阻止交付的 finding。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `.agents/skills/release-easydict/scripts/release-easydict.sh`
- `.agents/skills/release-easydict/scripts/release-notes-sync.py`
- `.agents/skills/release-easydict/tests/test_release_notes_sync.py`
- `.agents/skills/release-easydict/tests/test_release_redraft.py`
- `docs/releases/easydict.md`

### 后续事项

- 真实远程同步需显式执行 `sync-notes <version> --execute`；本次未执行。

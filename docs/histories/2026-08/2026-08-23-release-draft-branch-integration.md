## 2026-08-23 | 任务：隔离 Draft 并在 Publish 合并发布提交

**Links:** `docs/exec-plans/completed/2026-08-23-release-draft-branch-integration.md`

### 用户请求

Draft 不再直接修改远程 `dev` 和 `main`；先发布临时分支，等 Publish 成功后通过 merge
集成到最新本地 `dev`，再同步远程分支。

### 变更

- Draft 和同版本替换 Draft 只推送 `release/sync-<version>` 与版本 Tag。
- 新增 Publish Git 编排脚本，在公开 Release 前预检 merge，并在 appcast 安装后更新
  本地 `dev`、原子推送远程引用和清理临时分支。
- 更新远程验证、终端摘要、恢复状态、发布文档和 `release-easydict` Skill。
- 新增隔离 Git 测试，覆盖本地/远程 dev 分叉、当前其他分支含未提交文件、Publish
  merge、原子推送和清理。

### 设计意图

Draft 只是候选发布状态，不应提前污染开发分支或稳定分支。版本 Tag 固定已验证的版本
提交；Publish 使用普通 merge 保留发布提交、appcast 提交和后续开发提交的历史，避免
rebase 改写。远程推送前先安全移动本地 `dev`，并通过精确 lease 和 fast-forward 证明
阻止竞态或历史覆盖。

### 验证

- `bash -n scripts/release/*.sh`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py' -v`：11 个测试通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py' -v`：20 个测试通过。
- Skill `quick_validate.py`：通过。
- 普通 Draft、替换 Draft 和 Publish `--dry-run`：通过。
- `git diff --check`：通过。
- ShellCheck：本机未安装，未运行。

### 受影响文件

- `scripts/release/`
- `.agents/skills/release-easydict/`
- `docs/exec-plans/completed/2026-08-23-release-draft-branch-integration.md`
- `docs/histories/2026-08/2026-08-23-release-draft-branch-integration.md`

### 后续事项

- 首次真实发布时检查固定 Git 摘要以及远程 `release/sync-<version>` 的验证后清理结果。

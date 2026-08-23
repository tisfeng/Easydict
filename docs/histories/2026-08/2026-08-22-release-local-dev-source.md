## 2026-08-22 | 任务：修复发布流程的本地 dev 源同步

**Links:** scripts/release/

### 用户请求

让 `draft <version>` 自动将 `origin/dev` 同步合并到本地 `dev`，并基于同步后的本地分支发布；旧的过期 release worktree 应在安全条件下自动处理。

### 变更

- 新增本地 `dev` 同步步骤，支持 fast-forward 和保留本地提交的合并。
- 发布 worktree 从同步后的本地 `dev` 提交创建，并保存可恢复的源提交状态。
- 自动归档干净且未推送版本 Tag 的过期 worktree、分支和产物；resume 不替换原发布上下文。
- 更新发布工作流和中文发布文档。

### 设计意图

将远程 `origin/dev` 作为同步输入，而不是直接作为最终构建源，确保本地 `dev` 的最新提交参与发布。同时将新运行的自动修复与 resume 的上下文保护分开，避免重试时意外改变已构建发布的代码来源。

### 验证

- `bash -n scripts/release/*.sh`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `./scripts/release/release-easydict.sh draft 2.22.0 --dry-run`：通过，显示本地同步步骤。
- `git diff --check`：通过。

### 受影响文件

- `scripts/release/release-branch-sync.sh`
- `scripts/release/release-common.sh`
- `scripts/release/release-easydict.sh`
- `scripts/release/asc-workflow.json`
- `scripts/release/README.md`
- `docs/exec-plans/completed/2026-08-22-release-local-dev-source.md`

### 后续事项

- `shellcheck` 未安装；后续可在发布工具链中补充 shell 静态检查。

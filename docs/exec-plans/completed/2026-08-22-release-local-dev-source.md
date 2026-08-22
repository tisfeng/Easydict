# 基于本地 dev 的 Easydict 发布流程

**Status:** completed
**Created:** 2026-08-22
**Updated:** 2026-08-22
**Owner:** Codex
**Links:** scripts/release/

## 任务契约

- 任务模式：`implementation`
- 用户目标：让 `draft <version>` 自动同步远程 `dev` 到本地 `dev`，并基于同步后的本地 `dev` 发布。
- 允许动作：修改发布脚本、工作流定义、发布文档和本次变更的计划/历史文档；运行本地校验；创建一次本地提交。
- 允许修改路径：`scripts/release/`、`docs/exec-plans/`、`docs/histories/2026-08/`
- 预期交付物：可恢复、可诊断的本地 `dev` 发布源和过期 worktree 自动重建。
- 验收标准：干净的本地 `dev` 能同步 `origin/dev`；发布 worktree 从本地 `dev` 创建；安全条件满足时旧 worktree 自动归档重建；工作流和脚本校验通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`not attempted`

## 目标

使 `prepare`、`draft` 和完整 `release` 在构建前先同步本地 `dev`，然后从同步后的本地 `dev` 创建隔离发布 worktree。对没有远程版本副作用且干净的过期发布 worktree 自动归档并重建。

## 范围

- 包含：本地 `dev` 同步、发布源状态记录、过期 worktree 安全重建、工作流日志和文档。
- 不包含：自动推送修复代码、修改 Apple 认证、公证策略或发布频道默认值。

## 风险与缓解

- 风险：同步会修改本地 `dev`。
  - 缓解措施：只允许在当前分支为 `dev` 且工作树干净时执行；冲突时停止并保留冲突现场。
- 风险：重建可能丢失可恢复发布状态。
  - 缓解措施：只处理干净且尚未推送版本 tag 的生成 worktree；旧 worktree、状态和产物归档到版本目录下的 `stale-*` 目录。
- 风险：恢复流程切换到新的代码提交。
  - 缓解措施：同步阶段记录源提交；后续 resume 使用已保存的发布源和版本元数据。

## 里程碑

- [x] 确认范围和约束。
- [x] 实现本地 `dev` 同步和 worktree 重建。
- [x] 验证行为和文档。
- [x] 将本计划移到 `completed/`。

## 验证

- `bash -n scripts/release/*.sh`：通过。
- `jq -e . scripts/release/asc-workflow.json`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `git diff --check`：通过。
- `./scripts/release/release-easydict.sh draft 2.22.0 --dry-run`：通过，包含 `sync_local_dev` 步骤。
- `shellcheck`：当前环境未安装，未执行。

## 决策记录

- 2026-08-22：`origin/dev` 作为同步输入，本地 `dev` 的合并结果作为最终发布源。
- 2026-08-22：新运行允许自动归档干净且未推送的过期 worktree；resume 拒绝替换已保存的发布上下文。

## 进度记录

- 2026-08-22：完成脚本、工作流和发布文档修改，并通过静态与 dry-run 校验。

---
name: release-easydict
description: 编排 Easydict macOS 的 draft、publish、release 和 resume，整理英文 GitHub Release 内容，并处理发布后的 Issue 跟进。不用于一般的发布流程设计讨论。
---

# 发布 Easydict

使用仓库脚本发布 Easydict，并整理英文 GitHub Release 内容、跟进关联 Issue。

## 动作路由

Release 生命周期：

- `draft <version>`：创建或恢复经过验证的 Draft，整理英文正文和重点标题，然后停止。
- `draft <version> --replace-draft`：从已同步并提交的本地 `dev` 安全重建最新且匹配的
  未发布 Draft。
- `publish <version>`：整理已有且经过验证的 Draft，发布并验证，然后运行内部 Issue
  跟进的 `apply` 行为。
- `release <version>`：依次执行本 skill 的 `draft` 和 `publish` 行为。
- `resume <version-or-run-id>`：使用现有 skill 和 asc 状态，只继续未完成的 Release
  生命周期阶段。

执行这些动作时读取 `scripts/release/README.md` 和
[Release 生命周期](references/release-workflow.md)。`release` 始终表示由本 Skill 编排
`draft` 和 `publish`，不直接调用仓库脚本的一次性 `release` 动作。

发布后的 Issue 跟进：

- `issue-followup plan <version>`
- `issue-followup apply <version>`
- `issue-followup resume <version>`

执行这些动作时阅读 [references/issue-followup.md](references/issue-followup.md)
和 [references/issue-followup-policy.md](references/issue-followup-policy.md)。
`issue-followup resume` 恢复 Issue 跟进；`resume` 恢复 Release 生命周期。

## 授权边界

- 普通规划、解释、检查或“先给方案”请求保持只读，不因文中提到命令就运行它。
- 用户明确要求运行具体版本的 `issue-followup plan` 时，该命令会查询 GitHub 并写入
  `.tmp/release/<version>/state/issue-followup/` 下被忽略的本地状态，不评论或关闭 Issue。
  这属于获准的本地准备动作，不等于无副作用的 planning。用户禁止写文件时仅查询和
  分析，不运行该命令；必要时说明缺少可持久化的计划状态。
- 只有当用户针对具体版本或运行明确请求 `draft`、`publish`、`release`、Release
  `resume`、`issue-followup apply` 或 `issue-followup resume` 时，才执行远程修改。
- 用户明确请求 `publish` 或 `release` 后，同一版本通过远程发布验证时，也同时授权其
  内部 `issue-followup apply` 阶段。翻译、重点内容、评论或关闭已解决 Issue 不再另行
  请求确认。
- Draft 通过隔离 worktree 发布已提交的本地 `dev`，只推送临时
  `release/sync-<version>` 和版本 Tag，不修改本地或远程 `dev`、`main`。
- Publish 使用隔离 worktree 先完成 merge 预检。当前 checkout 位于其他分支时保持
  不变；当前 checkout 就是干净的 `dev` 时，发布提交验证后允许 fast-forward 更新。
  不覆盖未提交修改，也不 rebase 已发布提交。

## 默认值与完成条件

- 除非用户明确要求 `stable`，默认使用 `beta` channel，所有底层命令沿用同一 channel。
- `draft` 只有在 Draft、Tag、临时发布分支、changelog 和正文哈希全部验证后才完成；随后
  停止，不发布也不处理 Issue。
- `publish` 和 `release` 只有在 Release、appcast、Git 引用和 Issue 跟进都得到最终核验后
  才完成；Issue 阶段失败时不回滚已经发布的 Release 或已完成动作，而是报告可恢复状态。
- `resume` 只恢复现有运行的未完成阶段，不启动新的替换或发布。
- 最终报告 Release URL、标题、channel、notes 路径、Issue 摘要、底层 run ID 和可恢复
  状态路径；失败时说明准确阶段和已经发生的外部变更。

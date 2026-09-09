---
name: release-easydict
description: 编排 Easydict macOS 的 draft、publish、release 和 resume，整理英文 GitHub Release 内容，并处理发布后的 Issue 跟进。不用于一般的发布流程设计讨论。
---

# 发布 Easydict

使用仓库脚本发布 Easydict，并整理英文 GitHub Release 内容、跟进关联 Issue。

## 动作路由

Release 生命周期动作：

- `draft <version>`：创建或恢复经过验证的 Draft，整理英文正文和重点标题，然后停止。
- `draft <version> --replace-draft`：从已同步并提交的本地 `dev` 安全重建最新且匹配的
  未发布 Draft。
- `publish <version>`：整理已有且经过验证的 Draft，发布并验证，然后运行内部 Issue
  跟进的 `apply` 行为。
- `release <version>`：依次执行本 skill 的 `draft` 和 `publish` 行为。
- `resume <version-or-run-id>`：使用现有 skill 和 asc 状态，只继续未完成的 Release
  生命周期阶段。

执行这些动作时阅读 `scripts/release/README.md` 和
[references/commands.md](references/commands.md)。

发布后的 Issue 跟进使用以下动作：

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
- 绝不直接使用仓库脚本的一次性 `release` 动作。对本 skill 而言，`release` 表示由
  skill 管理的 Draft 创建、内容整理、发布、远程验证和 Issue 跟进。
- Draft 通过隔离 worktree 发布已提交的本地 `dev`，只推送临时
  `release/sync-<version>` 和版本 Tag，不修改本地或远程 `dev`、`main`。
- Publish 使用隔离 worktree 先完成 merge 预检。当前 checkout 位于其他分支时保持
  不变；当前 checkout 就是干净的 `dev` 时，发布提交验证后允许 fast-forward 更新。
  不覆盖未提交修改，也不 rebase 已发布提交。

## Release 工作流

除非用户明确要求 `stable`，否则默认使用仓库的 `beta` channel。所有底层发布命令都
沿用同一 channel。

1. 验证请求的版本、channel、当前 GitHub Release 状态、
   `.tmp/release/<version>/` 状态和相关 asc run ID。
2. 创建新 Draft 前，先根据上一个版本以来的已合并 PR 创建或更新
   `changelog/<version>.md`。正文使用简洁英文，保留 PR 作者、链接、New Contributors
   和 Full Changelog 范围；将该文件提交到本地 `dev`，然后运行：

   ```bash
   python3 scripts/release/release_notes.py validate \
     --file changelog/<version>.md --version <version>
   ```

3. 创建新 Draft 时运行：

   ```bash
   ./scripts/release/release-easydict.sh draft <version> [--channel <channel>]
   ```

   如果 Draft 已存在，验证它，不要删除或重建。仅当用户明确要求替换时使用：

   ```bash
   ./scripts/release/release-easydict.sh draft <version> \
     --replace-draft [--channel <channel>]
   ```

   现有 Release 必须是 GitHub 最新条目、保持同一 channel 的 Draft、匹配本地和远程
   Tag identity 以及本地发布状态，并且不在公开 appcast 中。绝不同时使用
   `--replace-draft` 和 `--build-number`。
4. Draft 会直接使用冻结的 `changelog/<version>.md`，并在创建后重新获取正文做一致性
   验证。根据真实 PR 选择重点并生成英文标题，先预览 `release_content.py apply`，再用
   `--execute` 只更新标题；helper 不编辑正文，并要求 Draft 正文仍与 changelog 一致。
5. 对于 `draft`，报告经过验证的 Draft、changelog 路径和正文哈希后停止，不发布也不
   处理 Issue。
6. 对于 `publish` 或 `release`，运行：

   ```bash
   ./scripts/release/release-easydict.sh publish <version> [--channel <channel>]
   ```

   仓库脚本会在 GitHub Release 公开前，将最新本地 `dev`、`origin/dev` 和版本提交
   进行 merge 预检。随后安装 appcast，将 appcast 提交 merge 到集成结果，先安全更新
   本地 `dev`，再使用 lease 原子更新 `origin/dev`、`origin/main` 和临时发布分支。
   远程验证成功后自动删除临时发布分支。在发布、appcast 安装和远程验证全部成功前
   不要继续。
7. 在本 skill 内继续执行 [references/issue-followup.md](references/issue-followup.md)
   定义的 `issue-followup apply <version>` 行为。它在修改前立即创建新计划，绝不依赖
   此前独立运行的 `plan`。
8. 报告 Release URL、标题、channel、notes 路径、固定三类 Issue 摘要、底层 run ID
   和可恢复状态路径。

## 状态

Release 内容状态保存在 `.tmp/release/<version>/state/`：

- `release-notes.json`：冻结版本、Markdown SHA-256、渲染器标识和 HTML SHA-256。

Issue 状态隔离保存在 `.tmp/release/<version>/state/issue-followup/`，并继续使用
schema v2。旧 schema-v1 实现直接存放在 `state/` 下的文件保留为审计数据，绝不自动
复用、迁移或删除。

对于 `--replace-draft`，旧内容和 Issue 文件只作为回滚数据。仓库工作流临时移走完整
旧状态，选择
`max(old Draft build, current project build, public appcast build) + 1`，再从已同步并
提交的本地 `dev` 重建。新 Draft 仍从该提交中的 `changelog/<version>.md` 创建，绝不将
旧 Draft 正文或 Issue 状态复制到新 generation。未完成的替换使用 asc run ID 恢复，
不要开始另一次替换。

## 内容决策

- changelog 中只翻译每个变更条目中由人编写的 PR 标题部分，并保持英文标题简洁；作者、
  PR 链接、贡献者和比较范围保持不变。
- 按以下顺序选择重点：安全/数据丢失/崩溃修复、重要的用户可见功能、重要的用户可见
  修复、较小的产品改进；只有不存在产品变更时才选择维护项。
- 使用 `<version> <emoji> <type>: <concise English summary>`，通常为 `✨ feat`、
  `🐞 fix`、`🔒 security`、`🚀 perf` 或 `🔧 chore`。
- 存在用户可见功能或修复时，不选择文档、生成资源、依赖升级或内部重构。

## 失败与恢复

- changelog 缺失、未提交、哈希漂移、渲染器版本不匹配或远端正文不一致时停止；已经
  创建的 GitHub Release 保持 Draft 状态。
- `--replace-draft` 构建或公证失败时，不修改旧的远程 Draft 和 Tag。后续切换失败时
  保留本地回滚数据；验证成功后删除该临时备份。
- 发布失败时不执行 Issue 动作，并使用 asc run ID 恢复。
- Draft 成功只表示临时发布分支、Tag 和 GitHub Draft 已就绪；不得将其报告为
  `dev`/`main` 已更新。
- Publish merge 冲突、本地 `dev` checkout 不干净或 lease 竞态失败时，保留集成
  worktree 和 `state/publish-git.env`，先解决根因，再使用 asc run ID 恢复。
- Issue 跟进失败时，绝不回滚已经发布的 Release、评论或 Issue 关闭操作。报告
  “发布成功，但 issue 后续处理未完成”，并使用：

  ```text
  $release-easydict issue-followup resume <version>
  ```

- 评论幂等性、仅关闭当前开放 Issue、固定报告格式和 Issue 决策验证由 Issue 跟进
  reference 定义，并由
  `.agents/skills/release-easydict/scripts/release_issues.py` 强制执行。

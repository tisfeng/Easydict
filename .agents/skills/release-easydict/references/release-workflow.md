# Release 生命周期执行契约

执行 `draft`、`publish`、`release` 或 Release `resume` 时读取本文档。本文件仅定义
Agent 必须遵守的动作选择、内容决策、外部写入和恢复契约。

## Git 与状态边界

- `draft` 生成、验证并提交 appcast，然后只推送指向 appcast 提交的
  `release/sync-<version>` 和指向版本提交的版本 Tag；不得把 Draft 提交直接推送到
  `origin/dev` 或 `origin/main`。
- `publish` 在 GitHub Release 公开前完成 merge 预检；公开 Release 后使用 Draft 阶段冻结的
  appcast 提交安全更新本地
  `dev`，再原子更新远程 `dev`、`main` 和临时发布分支。
- 远程验证通过后删除临时发布分支。版本 Tag 停留在版本元数据提交，`main` 停留在
  appcast 提交，`dev` 停留在包含最新开发提交和 appcast 提交的集成结果。
- Publish 失败时使用 asc run ID 恢复，不手工 rebase 或强推这些引用。

Release 内容状态保存在 `.tmp/release/<version>/state/`：

- `release-notes.json`：冻结版本、Markdown SHA-256、渲染器标识和 HTML SHA-256。

Issue 状态只使用 `.tmp/release/<version>/state/issue-followup/` 的 schema v2。直接存放在
`state/` 下的 schema-v1 文件保留为审计数据，不自动复用、迁移或删除。

## 工作流

1. 验证请求版本、channel、当前 GitHub Release、`.tmp/release/<version>/` 状态和相关
   asc run ID。
2. 创建新 Draft 前，根据上一个版本以来的已合并 PR 创建或更新
   `changelog/<version>.md`。正文使用简洁英文，应用统一 bot PR 过滤策略，保留有效 PR 作者、链接、New Contributors
   和 Full Changelog 范围；将文件提交到本地 `dev`，然后运行“验证 changelog”。
3. 运行“创建 Draft”。如果 Draft 已存在，验证并复用；只有用户明确要求替换时才运行
   “替换 Draft”。现有 Release 必须是 GitHub 最新条目、保持同一 channel 的 Draft、
   匹配本地和远程 Tag identity 以及本地发布状态，并且不在公开 appcast 中。
4. Draft 直接使用冻结的 changelog，并在创建后重新获取正文做一致性验证。根据真实 PR
   选择重点并生成英文标题，先预览标题更新，再用 `--execute` 执行；helper 不编辑正文。
5. `draft` 报告经过验证的 Draft、changelog 路径和正文哈希后停止。
6. `publish` 或 `release` 运行“发布 Draft”。仓库脚本会在公开 Release 前对最新本地
   `dev`、`origin/dev` 和版本提交做 merge 预检；Draft 阶段已经生成、验证并提交的
   appcast 会被校验后安全更新本地
   `dev`，再使用 lease 原子更新远程引用。发布、appcast 安装和远程验证全部成功前
   不继续。
7. 读取 [Issue 跟进](issue-followup.md) 和
   [Issue 决策策略](issue-followup-policy.md)，执行 `issue-followup apply <version>`。
   它在修改前创建新计划，不依赖此前独立运行的 `plan`。
8. 报告 Release URL、标题、channel、notes 路径、Issue 和无关联 PR 摘要、底层 run ID
   和可恢复状态路径。

归档使用长期的本地构建 worktree（`.tmp/release/cache/worktree`）和带 fingerprint 的
Release DerivedData。该 worktree 只服务于本地 Archive，不替代版本 release worktree，
不参与 appcast、Tag 或远程分支推送。普通 Archive 优先复用兼容缓存；失败时清理当前
fingerprint 并回退一次 clean Archive。缓存命中不改变签名、公证、stapling、appcast
或远程验证要求。

## 已发布日志的独立同步

如果发布完成后人工修改了 `changelog/<version>.md`，不要重新运行 `resume`、`draft` 或
`publish`。这些动作分别用于恢复中断的 ASC 工作流、重建 Draft 和发布 Draft；它们不会
把发布后的日志修订当作新的构建发布。

先预览目标 Release 正文和 `main/appcast.xml` 的 description 差异：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh sync-notes <version>
```

确认预览内容后才执行远程同步：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh sync-notes <version> --execute
```

可选参数包括 `--repo <owner/repo>`、`--notes-file <path>`、`--appcast-branch <branch>`
和 `--state <path>`。默认读取 `changelog/<version>.md`，默认更新远程 `main`。

该动作要求 Release 已公开且 Tag 与版本一致；不会修改 Draft、Tag、安装包、构建号、签名
或渠道。`--execute` 要求当前 worktree 干净，更新 Release 时使用 ETag，更新 appcast
时使用 Contents API 返回的 blob SHA；任一并发校验失败都会停止，避免覆盖他人修改。它
只允许改变目标版本 item 的 `<description>`。状态摘要保存在
`.tmp/release/<version>/state/notes-sync.json`，部分成功后再次执行会重新读取远程状态并
跳过已经一致的目标。

## 内容决策

- changelog 只翻译每个变更条目中由人编写的 PR 标题部分，并保持英文标题简洁；作者、
  PR 链接、贡献者和比较范围保持不变。
- Draft 阶段不评论 Issue/PR、不关闭 Issue、不推送 `main` 的 appcast；只有正式 Release
  远程验证成功后才执行 Issue 和无关联人工 PR 通知。PR 通知只发表评论，不关闭 PR。
- 按以下顺序选择重点：安全、数据丢失或崩溃修复；重要用户可见功能；重要用户可见修复；
  较小产品改进。只有不存在产品变更时才选择维护项。
- 标题使用 `<version> <emoji> <type>: <concise English summary>`，通常采用 `✨ feat`、
  `🐞 fix`、`🔒 security`、`🚀 perf` 或 `🔧 chore`。
- 存在用户可见功能或修复时，不选择文档、生成资源、依赖升级或内部重构作为重点。

## 命令选择规则

- 验证 changelog 后才能创建 Draft；Draft 标题 helper 必须先 preview，再在目标仍为相同
  Draft 且正文与 changelog 一致时执行。
- 普通 Draft 可以复用兼容的 Release 编译缓存；只有用户明确要求 clean build 时才传
  `--force-clean`。它只适用于 `prepare`、`draft` 和 `release`，不降低后续验证要求。
- 只有用户明确要求废弃并重建当前最新 Draft 时才传 `--replace-draft`；不得同时传
  `--build-number`。新 Draft 必须从已同步并提交的本地 `dev` 及其中的 changelog 创建，
  不复制旧 Draft 正文或 Issue 状态。
- 替换 Draft 失败后，只能使用输出的 run ID 执行 Release `resume`，不得启动新的替换。
- `publish` 必须使用 Draft 创建时的 channel。Skill 的 `release` 依次编排 `draft` 和
  `publish`，不得绕过两阶段的检查与人工边界。

## 失败与恢复

- changelog 缺失、未提交、哈希漂移、渲染器版本不匹配或远端正文不一致时停止；已经
  创建的 GitHub Release 保持 Draft 状态。
- `--replace-draft` 构建或公证失败时，不修改旧的远程 Draft 和 Tag。后续切换失败时保留
  本地回滚数据；验证成功后删除该临时备份。未完成的替换只使用 asc run ID 恢复。
- 发布失败时不执行 Issue 动作，并使用 asc run ID 恢复。
- Draft 成功只表示临时发布分支、版本 Tag、冻结的 appcast 提交和 GitHub Draft 已就绪，
  不代表 `dev` 或 `main` 已更新。
- Publish merge 冲突、本地 `dev` checkout 不干净或 lease 竞态失败时，保留集成 worktree
  和 `state/publish-git.env`；解决根因后使用 asc run ID 恢复。
- Issue 跟进失败时不回滚已经发布的 Release、评论或 Issue 关闭操作。报告“发布成功，
  但 issue 后续处理未完成”，并使用：

  ```text
  $release-easydict issue-followup resume <version>
  ```

评论幂等性、只关闭当前开放 Issue、固定报告格式和 Issue 决策验证由 Issue 跟进 reference
定义，并由 `.agents/skills/release-easydict/scripts/release_issues.py` 强制执行。

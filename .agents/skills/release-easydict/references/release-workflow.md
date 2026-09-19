# Release 生命周期

执行 `draft`、`publish`、`release` 或 Release `resume` 时读取本文档。以下命令均从仓库
根目录执行；将 `<version>` 替换为目标版本。

## Git 与状态边界

- `draft` 只推送 `release/sync-<version>` 和版本 Tag；不得把 Draft 提交直接推送到
  `origin/dev` 或 `origin/main`。
- `publish` 在 GitHub Release 公开前完成 merge 预检；安装 appcast 后安全更新本地
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
   `changelog/<version>.md`。正文使用简洁英文，保留 PR 作者、链接、New Contributors
   和 Full Changelog 范围；将文件提交到本地 `dev`，然后运行“验证 changelog”。
3. 运行“创建 Draft”。如果 Draft 已存在，验证并复用；只有用户明确要求替换时才运行
   “替换 Draft”。现有 Release 必须是 GitHub 最新条目、保持同一 channel 的 Draft、
   匹配本地和远程 Tag identity 以及本地发布状态，并且不在公开 appcast 中。
4. Draft 直接使用冻结的 changelog，并在创建后重新获取正文做一致性验证。根据真实 PR
   选择重点并生成英文标题，先预览标题更新，再用 `--execute` 执行；helper 不编辑正文。
5. `draft` 报告经过验证的 Draft、changelog 路径和正文哈希后停止。
6. `publish` 或 `release` 运行“发布 Draft”。仓库脚本会在公开 Release 前对最新本地
   `dev`、`origin/dev` 和版本提交做 merge 预检，安装并提交 appcast，安全更新本地
   `dev`，再使用 lease 原子更新远程引用。发布、appcast 安装和远程验证全部成功前
   不继续。
7. 读取 [Issue 跟进](issue-followup.md) 和
   [Issue 决策策略](issue-followup-policy.md)，执行 `issue-followup apply <version>`。
   它在修改前创建新计划，不依赖此前独立运行的 `plan`。
8. 报告 Release URL、标题、channel、notes 路径、固定三类 Issue 摘要、底层 run ID
   和可恢复状态路径。

## 内容决策

- changelog 只翻译每个变更条目中由人编写的 PR 标题部分，并保持英文标题简洁；作者、
  PR 链接、贡献者和比较范围保持不变。
- 按以下顺序选择重点：安全、数据丢失或崩溃修复；重要用户可见功能；重要用户可见修复；
  较小产品改进。只有不存在产品变更时才选择维护项。
- 标题使用 `<version> <emoji> <type>: <concise English summary>`，通常采用 `✨ feat`、
  `🐞 fix`、`🔒 security`、`🚀 perf` 或 `🔧 chore`。
- 存在用户可见功能或修复时，不选择文档、生成资源、依赖升级或内部重构作为重点。

## Helper 命令

### 验证 changelog

```bash
python3 scripts/release/release_notes.py validate \
  --file changelog/<version>.md --version <version>
```

### 创建或替换 Draft

```bash
./scripts/release/release-easydict.sh draft <version> [--channel <channel>]
```

只有用户明确要求废弃并重建当前最新 Draft 时，才使用：

```bash
./scripts/release/release-easydict.sh draft <version> \
  --replace-draft [--channel <channel>]
```

`--replace-draft` 自动递增并冻结构建号，绝不与 `--build-number` 同时使用。失败后不要
开始新的替换，应使用结果中的运行 ID：

```bash
./scripts/release/release-easydict.sh resume <run-id>
```

旧内容和 Issue 文件只作为回滚数据。仓库工作流临时移走完整旧状态，选择
`max(old Draft build, current project build, public appcast build) + 1`，再从已同步并提交的
本地 `dev` 重建。新 Draft 从该提交中的 changelog 创建，不复制旧 Draft 正文或 Issue
状态。

### 更新 Draft 标题

先预览：

```bash
python3 .agents/skills/release-easydict/scripts/release_content.py apply \
  --repo tisfeng/Easydict \
  --version <version> \
  --notes changelog/<version>.md \
  --title '<version> <emoji> <type>: <concise English summary>'
```

检查 JSON 计划后，在相同命令末尾追加 `--execute`。只有目标 Release 仍为相同 Draft 且
正文与 changelog 一致时才允许写入。

### 发布 Draft

```bash
./scripts/release/release-easydict.sh publish <version> [--channel <channel>]
```

## 失败与恢复

- changelog 缺失、未提交、哈希漂移、渲染器版本不匹配或远端正文不一致时停止；已经
  创建的 GitHub Release 保持 Draft 状态。
- `--replace-draft` 构建或公证失败时，不修改旧的远程 Draft 和 Tag。后续切换失败时保留
  本地回滚数据；验证成功后删除该临时备份。未完成的替换只使用 asc run ID 恢复。
- 发布失败时不执行 Issue 动作，并使用 asc run ID 恢复。
- Draft 成功只表示临时发布分支、Tag 和 GitHub Draft 已就绪，不代表 `dev` 或 `main`
  已更新。
- Publish merge 冲突、本地 `dev` checkout 不干净或 lease 竞态失败时，保留集成 worktree
  和 `state/publish-git.env`；解决根因后使用 asc run ID 恢复。
- Issue 跟进失败时不回滚已经发布的 Release、评论或 Issue 关闭操作。报告“发布成功，
  但 issue 后续处理未完成”，并使用：

  ```text
  $release-easydict issue-followup resume <version>
  ```

评论幂等性、只关闭当前开放 Issue、固定报告格式和 Issue 决策验证由 Issue 跟进 reference
定义，并由 `.agents/skills/release-easydict/scripts/release_issues.py` 强制执行。

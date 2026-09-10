# submit-pr 工作流契约

本文件说明 `submit_pr.py` 与调用 Agent 的职责，以及各阶段的检查和执行规则。执行
`plan`、默认或 `draft` 模式时都要完整阅读。

## Repository 拓扑发现

helper 只接受指向 `github.com` 的 SSH 或 HTTPS remote，并按以下顺序解析：

1. base repository：显式 `--repo`、`GH_REPO`、所有 GitHub remote 所属 fork 网络的
   唯一根仓库；多个根仓库时停止。
2. base remote：显式 `--base-remote`，否则唯一指向 base repository 的 remote；不能
   仅因名称是 `origin` 就信任它。
3. base branch：显式 `--base`、当前分支的 `branch.<name>.gh-merge-base`、GitHub
   repository 的 default branch。
4. head remote：显式 `--head-remote`、`branch.<name>.pushRemote`、
   `remote.pushDefault`、唯一 fork remote、当前 upstream、base remote。任一步产生多个
   有效候选时停止。
5. head repository 必须与 base repository 位于同一 fork 网络；跨 fork PR 使用
   `<owner>:<branch>` 作为 `gh` 的 head 参数。

显式参数只解决歧义，不能绕过 remote URL、fork 网络和 GitHub 返回身份的校验。
同次拓扑发现中，显式 repository 与已查询的 remote repository 相同时复用元数据；每次
`plan` 或 `apply` 调用重新发现，不跨调用缓存，也不省略写入前后的状态校验。

## 分支决策

任务分支使用 Conventional 格式 `<type>/<kebab-case-summary>`。

base branch、GitHub default branch 和重复传入的 `--protected-branch` 都属于保护分支。

- 当前分支是保护分支或不符合 Conventional 格式：必须提供
  `--head-branch <type>/<kebab-case-summary>`。helper 从冻结 HEAD 创建或复用该本地
  ref，但不切换 checkout、不移动当前分支。
- 当前已经是合规任务分支：直接使用；如果同时提供 `--head-branch`，名称必须相同。
- Detached HEAD：停止。

apply 先 fetch 精确 base ref，再要求 `<base-remote>/<base>` 是 HEAD 的祖先且范围至少
包含一个提交。该拓扑检查不替代调用 Agent 对提交范围和任务边界的语义审查。

## 工作树与提交

- `plan` 使用 `GIT_OPTIONAL_LOCKS=0` 执行 Git 读取，可以报告 staged、unstaged 和
  untracked 状态，但不 fetch、不创建 ref、不写临时文件。
- `apply` 要求工作树完全干净。
- helper 不运行 `git add` 或 `git commit`。已有 staged 内容由调用 Agent 根据目标
  仓库交付规则处理；有 unstaged 或 untracked 内容时停止。
- 默认/draft 的调用方在最终 plan 前完成允许的 staged 提交和精确 base fetch，解决首次提交或
  缺少 cached base 的准备问题。纯 plan 不执行这些动作，缺少前提时只报告限制。
- helper 不修改提交历史，也不把无关提交从范围中自动剔除。

## 模板优先的正文契约

`plan`、默认和 `draft` 均依据用户请求、目标仓库规则、真实提交范围与 diff 起草正文。
PR 标题使用 Angular-style `type(scope): subject`，说明主要行为。Summary 解释实际改动及原因；
Verification 只列出实际执行的检查及结果；Issue 仅使用用户提供或有明确证据的引用。

目标仓库模板优先保留原有标题、顺序、非占位说明和 checklist。以下语义标题会接收调用方
提供的内容：

1. Summary、Description 或 Changes
2. Linked Issues、Related Issues 或 Issues
3. Verification、Testing 或 Tests
4. Screenshots 或 Screenshot

模板发现兼容 GitHub 规则：在仓库根目录、`docs/` 或 `.github/` 中查找文件名大小写不
敏感的 `pull_request_template.md` 或 `pull_request_template.txt`；也在这三个位置中
查找名称大小写不敏感的 `PULL_REQUEST_TEMPLATE/` 目录，并读取其中的 `.md` 或 `.txt`
模板。

没有模板时使用内置四段式骨架，不创建模板文件；只有一个模板时自动使用；多个模板时
必须显式 `--template`。大小写不敏感文件系统上的同一文件按 inode 去重。

映射段落中的非占位提示和 checklist 会保留，其他项目专属二级段落按原顺序附加。模板缺少
某个语义段落时，helper 才在模板内容之后追加对应的内置默认段落，确保 Summary、
Verification、Issue 和 Screenshots 内容均可见。`--extra-body-file <path|->` 可补充项目
专属段落，但不能重复任一语义段落。

- Summary 和 Verification 不能为空。
- 没有关联 Issue 时保持该区域为空。
- 非 UI 修改写入 `N/A`。
- UI 修改写入固定提示，请用户在 GitHub PR 页面补充截图；不因截图缺失停止或自动改为 Draft。

## Issue 策略

`--issue-policy` 决定 GitHub 自动关闭引用的约束：

- `neutral`（默认）：调用 Agent 不主动生成 `Fixes`、`Closes`、`Resolves` 等自动关闭语法；
  允许目标仓库模板或用户显式附加正文包含该语法。helper 不生成 closing keyword，也不对模板
  和提交历史施加额外限制。
- `allow`：显式表明目标工作流允许 closing keyword。
- `forbid`：扫描正文和 base..HEAD 的完整提交信息，并在创建后要求
  `closingIssuesReferences == []`。

`--issue` 本身只接受 `#123`、完整 Issue URL 和 `owner/repo#123`，不会自动加
`Fixes`、`Closes` 或 `Resolves`。

## GitHub 写入

push 始终使用计划冻结的 SHA、唯一验证过的 push URL 和精确 refspec。若 head remote 配置了
多个 push URL，必须先收敛为一个目标，否则流程在远程写入前停止：

```bash
git push <validated-push-url> <planned-head-sha>:refs/heads/<head-branch>
```

同仓库 PR 使用 `--head <head-branch>`；fork PR 使用 `--head <owner>:<head-branch>`：

```bash
gh pr create \
  --repo <base-owner/base-repo> \
  --base <base-branch> \
  --head <head-query> \
  --title <title> \
  --body-file <system-temporary-file>
```

`draft` 追加 `--draft`。正文临时文件不写入目标仓库，并在命令返回后清理。禁止依赖
`gh` 隐式推断 fork、push、title 或 body。

## 幂等验证

创建前按 base repository、base branch 和 head query 查询开放 PR：

- 没有 PR：push 并创建。
- 恰好一个且仓库、base/head 分支、title、body 和 Draft 等不可变计划字段相同：允许复用。
  远程 head 与计划 SHA 相同则不推送；远程 head 是计划 SHA 的祖先则普通快进推送。推送后
  再验证 head SHA 和完整 PR 状态。
- 多个 PR，或任一字段不同：停止。

创建或复用后验证：

- `state == OPEN`
- base branch、head branch 和 head SHA 与计划一致
- base/head repository 身份及 `isCrossRepository` 与计划一致
- title、body、`isDraft` 与计划一致
- `forbid` 策略下 `closingIssuesReferences` 为空

验证失败后不创建第二个 PR，也不自动覆盖现有 PR。push 成功但创建失败时保留远程分支；创建
成功但最终验证中断时保留已有 PR。使用相同内容重试原 apply 命令，重新发现并核验已完成动作。
远程分支与计划 SHA 相同则复用，是其祖先则普通快进推送，领先或分叉时停止。
目标仓库要求特定 Issue 策略时显式传入 `--issue-policy`；未指定时使用 `neutral`。

## 输出

helper 向 stdout 输出 JSON。apply 结果包含：

- PR URL 和编号
- base repository、remote 和 branch
- head repository、remote、branch 和冻结 SHA
- `is_cross_repository`、`draft`、`issue_policy`
- `branch_action`：`created`、`updated`、`reused` 或 `current`
- `push_action`：`created`、`updated` 或 `reused`
- `pr_action`：`created` 或 `reused`
- `needs_screenshots`：UI 修改时为 `true`

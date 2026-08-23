# submit-pr 工作流契约

本文件定义 `submit-pr` helper 与 Agent 之间的确定性边界。执行 `plan`、默认或
`draft` 模式时都要完整阅读；仅在 skill 之外起草普通 PR 文案时不加载。

## 分支决策

默认 remote 为 `origin`，GitHub 仓库为 `tisfeng/Easydict`，base 为 `dev`。

- 当前分支为 `dev`：要求 `HEAD` 领先 `origin/dev`，从 HEAD 创建新的 Conventional
  任务分支，但不切换 checkout。任务分支名由调用方按 `git-commit` 的分支命名规则
  提供。
- 当前已经是普通任务分支：使用当前分支；如果同时提供 `--head-branch`，名称必须完全
  相同。
- 当前分支为 `main`、`release/*` 或 `review/*`：停止。
- Detached HEAD：停止；本 skill 不负责挂接 detached checkout。

调用 apply 时先 fetch `origin/dev`，再要求 `origin/dev` 是 HEAD 的祖先且范围至少包含
一个提交。该检查只证明 Git 拓扑有效；Agent 仍必须根据请求检查提交和文件是否属于同一
任务。

## 工作树与提交

- `plan` 可以读取脏工作树，但必须在输出中报告 staged、unstaged 和 untracked 状态，
  不改变它们。
- `apply` 要求工作树完全干净。
- 仅 staged 内容由调用方通过 `git-commit` skill 提交；本 helper 不运行 `git add` 或
  `git commit`。
- 有 unstaged 或 untracked 内容时不进入 apply，避免 branch 或 remote 操作与用户现场
  混在一起。

## 模板字段

helper 必须直接读取 `.github/pull_request_template.md`，确认以下四个二级标题恰好出现
一次且顺序不变：

1. `变更说明 / Summary`
2. `关联 Issue / Linked Issues`
3. `验证 / Verification`
4. `截图 / Screenshots`

渲染时移除模板注释和 `-` 占位符，只保留标题与调用方提供的内容。

- Summary 和 Verification 不能为空。
- 没有关联 Issue 时保持该区域为空。
- 非 UI 修改写入 `N/A`。
- UI 修改写入固定提示：

  ```text
  请在 GitHub PR 页面补充截图。 / Please add screenshots on the GitHub PR page.
  ```

缺少截图不是失败条件，也不会自动切换 Draft 状态。

## GitHub 写入

helper 使用显式 refspec push：

```bash
git push origin <planned-head-sha>:refs/heads/<remote-head>
```

push 使用计划冻结的确切 SHA，不能使用可能在并发操作中移动的本地 branch ref。
之后使用：

```bash
gh pr create \
  --repo tisfeng/Easydict \
  --base dev \
  --head <remote-head> \
  --title <title> \
  --body-file <body-file>
```

`draft` 模式追加 `--draft`。禁止依赖 `gh` 的隐式 fork、push、title 或 body 推断。

## 幂等验证

创建前查询 exact head/base 的开放 PR：

- 没有 PR：继续 push 和创建。
- 恰好一个且所有计划字段相同：复用并验证。
- 多个 PR，或任一字段、head SHA 不同：停止。

创建或复用后必须验证：

- `state == OPEN`
- `baseRefName == dev`
- `headRefName` 等于目标任务分支
- `headRefOid` 等于本地 HEAD
- title、body、`isDraft` 与计划一致
- `closingIssuesReferences` 为空

验证失败后不创建第二个 PR，也不自动编辑现有 PR。

## 输出

helper 向 stdout 输出 JSON。apply 状态包含：

- PR URL 和编号
- base、head 和 head SHA
- `draft` 状态
- `branch_action`：`created`、`reused` 或 `current`
- `push_action`：`created`、`updated` 或 `reused`
- `pr_action`：`created` 或 `reused`
- `needs_screenshots`：UI 修改时为 `true`
- 正文和状态文件路径

UI 修改的最终用户报告必须附带 PR URL，并明确提示用户到该页面补充截图。

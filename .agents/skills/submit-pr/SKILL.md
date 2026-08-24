---
name: submit-pr
description: >
  根据 Easydict 当前提交准备并创建 GitHub Pull Request：检查提交范围，复用仓库
  PR 模板生成标题和正文，安全推送任务分支，并创建或复用 PR 后验证。适用于用户明确
  要求计划、创建、提交或恢复 Easydict PR；不用于 PR review、merge 或仅本地提交。
---

# 提交 Easydict PR

将当前 checkout 中已经提交的连贯工作安全地提交为指向 `dev` 的 GitHub PR。

## 模式

- `plan`：只读检查并预览标题、正文、提交范围和目标分支；不 fetch、不创建分支、
  不写临时文件、不 push、不创建 PR。
- 默认：准备任务分支，显式 push 到 `origin`，创建或复用正式 PR，并验证远程状态。
- `draft`：与默认模式相同，但创建 Draft PR。

用户没有指定模式时使用默认模式。重复执行相同请求就是恢复机制，不提供单独的
`resume`。第一版不自动更新已经存在的 PR。

## 必需流程

1. 阅读 [references/workflow.md](references/workflow.md)。
2. 运行 `git status --short --branch`，记录当前分支、HEAD、staged、unstaged 和
   untracked 边界。
3. 只根据当前请求、实际提交范围和 diff 起草 PR 内容：
   - 标题使用简洁的 Angular-style 行为摘要。
   - `变更说明` 解释实际改动及原因。
   - `关联 Issue` 只使用用户提供或有明确证据的引用；没有则留空。
   - `验证` 只列出实际执行过的检查和结果。
   - 非 UI 修改的截图区域填写 `N/A`；UI 修改填写中英双语提示，要求用户在 GitHub
     PR 页面补充截图。
4. 使用 helper 的 `plan` 子命令渲染并检查正文。不要使用
   `gh pr create --dry-run`，因为它仍可能 push。
5. `plan` 模式展示 helper 结果后停止。
6. 默认或 `draft` 模式下：
   - unstaged 或 untracked 内容非空时停止；绝不自动运行 `git add`。
   - 仅 staged 内容非空时，先完整阅读并调用 `git-commit` skill；它只能提交现有
     staged diff。提交后要求工作树干净。
   - 工作树干净时复用现有提交。
7. 重新检查完整 `origin/dev..HEAD` 提交和文件范围。范围包含无关工作、为空或来源不明
   时停止，不自动 rebase、merge 或修正历史。
8. 使用 helper 的 `apply` 子命令执行 fetch、任务分支准备、显式 push、PR 创建或复用
   以及创建后验证。`draft` 模式追加 `--draft`。
9. 最终报告 PR URL、base、head、head SHA、Draft 状态、本次是否创建远程分支和 PR，
   以及是否需要在 GitHub PR 页面补充截图。

## 内容输入

helper 接收 Agent 根据真实上下文整理的字段：

```bash
python3 .agents/skills/submit-pr/scripts/submit_pr.py plan \
  --title '<title>' \
  --summary '<summary>' \
  --verification '<verification>' \
  --head-branch '<type/kebab-case-summary>' \
  [--issue '#123'] \
  [--issue 'https://github.com/tisfeng/Easydict/issues/123'] \
  [--issue 'owner/repo#123'] \
  [--ui-change]
```

创建时将 `plan` 改为 `apply`。字符串必须作为单独参数安全传递，不通过 `eval` 或拼接
可执行 shell。当前 checkout 已经是任务分支时可以省略 `--head-branch`；当前分支是
`dev` 时必须提供按 `git-commit` **Branch Name Guidance** 推导的任务分支名。

## 安全边界

- 固定 GitHub 仓库为 `tisfeng/Easydict`、remote 为 `origin`、base 为 `dev`，除非用户
  明确指定其他同仓库目标。
- 当前位于 `dev` 时，从当前 HEAD 创建任务分支但不切换 checkout、不移动本地 `dev`，
  也不 push `origin/dev`。
- 不自动 push `main`、`dev`、`release/*` 或 `review/*`。
- 不执行 force push、rebase、merge、reset、stash、branch delete 或 remote delete。
- 不自动添加 reviewer、label、milestone、project，不 merge PR，不评论或关闭 Issue。
- 不自动修改已有 PR。相同 head/base 已有开放 PR 时只复用并验证；内容或 SHA 不一致时
  停止并报告。
- 不生成、上传或检查截图。UI 修改缺少截图不会阻止 push、创建或验证 PR。
- `plan` 模式完全只读。默认和 `draft` 模式的外部写入仅限显式任务分支 push 和创建
  一个 PR。

## 关联 Issue

允许 `#123`、完整 `https://github.com/<owner>/<repo>/issues/123` 和
`owner/repo#123`。禁止生成 `Fixes`、`Closes`、`Resolves` 等自动关闭语法，也不要通过
Development 侧栏建立自动关闭关联。创建后 helper 要求 `closingIssuesReferences` 为空。

## 恢复与停止条件

- 远程分支不存在：创建。
- 远程和本地 SHA 相同：复用。
- 远程是本地祖先：允许普通 fast-forward push。
- 远程领先或分叉：停止，绝不 force push。
- push 成功而 PR 创建失败：保留远程分支；重复原命令继续创建。
- PR 已创建而最终验证中断：重复原命令查找同一 head/base PR 并只重新验证。
- 已有 PR 的标题、正文、Draft 状态或 head SHA 与本次计划不同：停止，不覆盖用户内容。

helper 会把 apply 产物保存在 gitignored 的 `.tmp/submit-pr/`；`plan` 不写入该目录。

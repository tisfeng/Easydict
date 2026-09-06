---
name: submit-pr
description: >
  根据当前 Git checkout 的已提交变更规划、创建或继续 GitHub Pull Request
  提交流程，安全推送任务分支、复用远程状态并验证最终 PR。不用于
  PR review、merge 或仅本地提交。
---

# 提交 GitHub PR

根据当前 Git checkout 的已提交变更，创建或复用 GitHub Pull Request。

## PR 规范

- PR 标题使用 Angular-style：`type(scope): subject`。
- 任务分支使用 Conventional 格式：`<type>/<kebab-case-summary>`。
- PR 正文按以下顺序包含四个规范段落，每个仅出现一次：
  1. `变更说明 / Summary`
  2. `关联 Issue / Linked Issues`
  3. `验证 / Verification`
  4. `截图 / Screenshots`
- 保留目标仓库 PR 模板中非占位的说明、checklist 和额外段落。
- 目标仓库没有 PR 模板时使用内置四段式骨架，不创建模板文件，也不中断流程。
- 非 UI 修改的截图段填写 `N/A`；UI 修改只提示用户在 GitHub PR 页面补充截图，不能
  因缺少截图中断流程。

## 模式

- `plan`：只读发现仓库拓扑，预览提交范围、标题、正文、base、head 和 push remote；
  不 fetch、不创建分支、不写仓库文件、不 push、不创建 PR。
- 默认：使用 helper 的 `apply`，fetch base、推送任务分支、创建或复用正式 PR 并验证。
- `draft`：与默认相同，但创建 Draft PR。

用户没有指定模式时使用默认模式。

## 必需流程

1. 完整阅读 [references/workflow.md](references/workflow.md)。
2. 运行 `git status --short --branch`，记录当前分支、HEAD、staged、unstaged 和
   untracked 边界。
3. 根据目标仓库规则、用户请求、真实提交范围和 diff 起草 PR 内容：
   - 标题描述最重要的可观察行为。
   - Summary 解释实际改动及原因。
   - Linked Issues 只使用用户提供或有明确证据的引用；没有则留空。
   - Verification 只列出实际执行过的检查和结果。
4. 使用 helper 的 `plan` 子命令渲染和检查正文。禁止使用
   `gh pr create --dry-run`，因为它仍可能 push。
5. `plan` 模式展示结果后停止。
6. 默认或 `draft` 模式：
   - unstaged 或 untracked 内容非空时停止；绝不自动运行 `git add`。
   - 仅 staged 内容非空时，按目标仓库交付规则调用可用的 `git-commit` Skill；helper
     本身不提交。提交后要求工作树干净。
   - 工作树干净时复用现有提交。
7. 重新检查完整 `<base-remote>/<base>..HEAD` 提交和文件范围。范围包含无关工作、为空
   或来源不明时停止；不自动 rebase、merge 或修正历史。
8. 使用 helper 的 `apply` 子命令执行 fetch、精确 refspec push、PR 创建或复用和远程
   验证。`draft` 模式追加 `--draft`。
9. 最终报告 PR URL、base repository/branch、head repository/branch、head SHA、Draft
   状态、分支和 PR 动作，以及是否需要在 GitHub 页面补充截图。

## Helper 调用

最小调用示例：

```bash
python3 .agents/skills/submit-pr/scripts/submit_pr.py plan \
  --title '<type(scope): subject>' \
  --summary '<summary>' \
  --verification '<verification>' \
  --head-branch '<type/kebab-case-summary>' \
  [--issue '#123'] \
  [--issue 'https://github.com/owner/repo/issues/123'] \
  [--issue 'owner/repo#123'] \
  [--ui-change]
```

创建时把 `plan` 改为 `apply`。字符串必须作为独立参数传递，不能通过 `eval` 或拼接
可执行 shell。只有当前分支已经是合规任务分支时才可省略 `--head-branch`。

存在拓扑歧义或项目专属规则时使用：

```bash
  [--repo owner/repo] \
  [--base main] \
  [--base-remote upstream] \
  [--head-remote fork] \
  [--protected-branch production] \
  [--template .github/PULL_REQUEST_TEMPLATE/feature.md] \
  [--extra-body-file /path/to/project-sections.md] \
  [--issue-policy neutral|allow|forbid]
```

## 安全边界

- 只支持 GitHub remote；不创建 fork，不猜测存在歧义的 repository、base 或 remote。
- base/default/显式 `--protected-branch` 不能作为 PR head；从这些分支发布时创建或复用
  独立任务分支，但不切换当前 checkout、不移动当前分支，也不 push base。
- 不 force push，不执行 rebase、merge、reset、stash、branch delete 或 remote delete。
- 不自动添加 reviewer、label、milestone、project，不 merge PR，不评论或关闭 Issue。
- 相同 base/head 已有开放 PR 时只复用并验证；title、body、Draft、head SHA 或 repository
  身份不一致时停止，不覆盖维护者修改。
- `plan` 不产生本地或远程写入。`apply` 的仓库写入仅限必要 fetch、本地任务分支 ref 和
  显式 head remote push；PR 正文临时文件写入系统临时目录并在创建后移除。

## Issue 策略

- `neutral`（默认）：不主动生成自动关闭语法，但允许目标仓库模板或显式附加正文包含
  这类语法。
- `allow`：与 GitHub 常规工作流兼容，明确允许自动关闭引用。
- `forbid`：正文和提交信息均禁止 `Fixes`、`Closes`、`Resolves` 等自动关闭语法，创建
  后还必须验证 `closingIssuesReferences` 为空。

目标仓库要求特定 Issue 策略时，显式传入 `--issue-policy`。

## 恢复与停止条件

- 远程任务分支不存在：创建。
- 远程和冻结 SHA 相同：复用。
- 远程是冻结 SHA 的祖先：允许普通 fast-forward push。
- 远程领先或分叉：停止，绝不 force push。
- push 成功而 PR 创建失败：保留远程分支；重复原命令继续创建。
- PR 已创建而最终验证中断：重复原命令查找相同 repository/base/head PR 并重新验证。
- 多模板、多 base remote、多候选 head remote 或 fork 网络不一致：停止并要求显式参数。

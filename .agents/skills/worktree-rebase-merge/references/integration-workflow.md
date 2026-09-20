# Worktree 集成协议

执行 `worktree-rebase-merge` 时读取。`<worktree-skill-dir>` 指实际加载的本 Skill 目录。

## 稳定预检

优先运行：

```bash
python3 "<worktree-skill-dir>/scripts/collect-integration-facts.py" \
  --source <source-path> [--target <target-branch>] \
  [--source-branch <detached-candidate>]
```

未提供 `--target` 时，helper 按本协议解析远程 HEAD；提供后不查询远程。核对
`schema_version`、`stable`、源/目标 OID、status、进行中操作、目标 worktree、detached
候选动作和完整提交范围。helper 只读，不判断用户授权，也不替代每次 Git 写入前的复验。

默认目标分支按以下规则解析：

1. 优先使用 `origin`；如果没有 `origin` 且恰好只有一个 remote，使用该 remote。
2. 通过 `git ls-remote --symref <remote> HEAD` 读取 `ref: refs/heads/<branch> HEAD`。
3. 实时查询失败或没有 branch ref 时，只可读取本地 symbolic ref 作为候选报告，
   不默默信任缓存；停止并请用户指定或确认。

本地目标分支必须存在。普通集成从 `git worktree list --porcelain -z` 中查找分支恰好为
`<target-branch>` 的 checkout。多个目标 worktree 时选择第一个干净项；全部为脏时记录
每个路径和 status，按下文暂停。

## 挂接 Detached HEAD

当 `git branch --show-current` 为空时：

1. 记录 HEAD 和完整 status。
2. 依次从 staged diff、unstaged/untracked 内容、`git log <target>..HEAD` 的第一个明确来源
   推断任务意图。全部为空时停止，不创建分支。
3. 调用 `git-commit` 的分支命名组合能力，只获取候选名。
4. 使用 `git check-ref-format --branch <branch-name>` 验证。候选不存在时运行
   `git switch -c <branch-name>`；如果它指向原 detached commit 且未被其他 worktree 使用，
   运行 `git switch <branch-name>`；否则使用 `-2`、`-3` 等未占用后缀。
5. 不移动或覆盖现有分支。挂接后确认 HEAD 仍是原提交，且 staged、unstaged 和
   untracked 状态完全不变。

## 提交与脏目标暂停

源与目标相同时，只调用 `git-commit`；不查找或创建目标 worktree，不 rebase、merge、
fetch、pull 或 push。

普通集成使用 `git-commit` 处理获准源变更。只有该步骤改变 HEAD 时标记
`created-this-run`；源已有干净提交时标记 `preexisting-source-commit`。无可提交内容
且工作树仍不干净时停止；只从干净源执行 rebase。

如果目标分支只有脏 worktree，先完成源分支创建和源提交，然后在范围检查、rebase
或 merge 前停止。不修改目标 worktree；报告源 hash、脏目标路径和文件，以及尚未执行
的步骤。用户清理后说“继续”时，重新解析目标和 worktree 状态；源没有新变更时复用
已有提交，否则在 rebase 前再使用 `git-commit`。

## Rebase

- 冻结 `git log --oneline <target>..<source>` 和 `git diff --stat <target>...<source>` 的完整集成范围。
- 路径限制需检查范围内每个提交曾触及的路径，包括后来撤销的变更。
- 用户明确调用本 Skill 且未限定提交时，`<target>..<source>` 的全部源提交都是集成范围。
  用户限定的提交范围与实际不一致时停止，不用 reset、交互式 rebase 或 cherry-pick 静默改写。
- 从源 worktree 运行 `git rebase <target>`。冲突时只处理位于允许路径且不需要产品判断的
  机械冲突，只暂存已解决文件并运行 `git rebase --continue`；其他冲突保留现场并停止。
- rebase 后要求源 worktree 干净，运行 `git diff --check <target>...HEAD`；只在仓库规则、
  用户请求或变更风险要求时扩大验证。

## Merge 与临时 worktree

- 已有目标 worktree 时，确认其分支和干净状态后从该路径合并。
- 没有目标 worktree 时，在仓库外创建专用临时目录，运行
  `git worktree add <temporary-path> <target>`，并复验分支与干净状态。
- 不使用 `git update-ref`、`git branch -f` 或切换其他 checkout 来更新目标分支。
- 运行 `git merge <source>`；除非用户明确要求，不强制 `--no-ff`、squash、再次 rebase 或 push。
- merge 冲突使用与 rebase 相同的机械冲突边界。临时 worktree 中发生冲突或失败时保留目录，
  报告恢复路径；成功合并后使用 `git worktree remove <temporary-path>` 删除。

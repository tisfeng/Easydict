# PR 本地准备与 latest-base

仅在用户允许 Git 准备的 PR 审查中读取。用户要求只读、不改变 Git 状态或不切分支时，
不使用本协议绕过限制。

## 分支与 remote 安全

- contributor remote 名称必须与 PR head repository owner login 完全一致。
  同名 remote 已指向其他位置时停止并请用户决定。
- 默认本地模式优先使用 PR head 分支名。只有该名称不可安全使用时，创建
  `review/pr-<number>-<head-short-sha>`；不改变冲突分支。
- 同名分支只能 fast-forward 到准确 `headRefOid`，不得包含额外本地提交或与远程分叉。
  领先、分叉、upstream 不匹配或被其他 worktree 占用时，可回退到上述 review 分支。
- 既有 review 分支只在它干净、位于准确 head 且 tracking `<owner>/<head-branch>` 时复用；
  否则停止。不 detached checkout remote-tracking ref 或直接审查 fetch ref。
- 除非用户明确要求隔离 worktree 或 latest-base，不创建其他命名的分支。

显式 worktree 模式使用：

- 普通审查分支：`review/pr-<number>-<head-short-sha>`。
- latest-base 分支：`review/pr-<number>-merge-<head-short-sha>`。
- 路径：`../.review-pr-worktrees/<repo>/pr-<number>[-merge]-<head-short-sha>`。

审查后保留分支或 worktree 供调试，不自动删除。

## 准备 helper

使用初始证据快照的 `headRefOid` 作为 `--expected-head`。普通本地审查：

```bash
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" \
  --expected-head <head-sha> --json <pr-ref>
```

显式隔离 worktree：

```bash
bash "<review-pr-skill-dir>/scripts/prepare-pr-branch.sh" \
  --worktree --expected-head <head-sha> --json <pr-ref>
```

只在用户明确授权 latest-base 时，为对应命令增加 `--merge-latest`。仅有
`schema_version: 1`、`status: prepared`，且 repo/number、head、base、merge-base、
checkout/upstream、collision 和 integration 模式均符合初始证据时才接受回执。
`failed` 回执保留停止阶段，不自动清理或重启写入。

大 PR 中已使用快照文件时，可按
[快照传输协议](snapshot-protocol.md#复用准备元数据) 传入已校验文件，减少重复元数据查询。
这不取消 helper 的实际 fetch、head/base 检查和本地状态验证。

## 普通审查与 latest-base

没有 latest-base 授权时，即使 GitHub 报告冲突或 base 领先，仍将 PR head checkout 到安全
分支，按其提交时状态审查。准备回执已冻结最新 base；使用：

```bash
git merge-base --is-ancestor <frozen-base-sha> <remote-head-sha>
```

检查失败表示 PR 落后，不自动合并。需要只读冲突信号时可使用：

```bash
git merge-tree <frozen-merge-base> <frozen-base-sha> <remote-head-sha>
```

只有明确要求更新最新 base、解决冲突或审查集成结果时，才使用 `--merge-latest`。
本地模式在已选的 head 同名或 collision fallback 分支上运行 `git merge --no-edit`，
保留分支名。只有显式 `--worktree --merge-latest` 使用 `review/pr-<number>-merge-...` 命名。
执行前说明可能创建本地 merge commit；未获 latest-base 授权时在创建该集成分支前停止。

## 冲突恢复

merge helper 因冲突停止时，在实际准备 checkout 中检查：

```bash
git status --short
git diff --name-only --diff-filter=U
git diff --cc
```

阅读冲突代码和周边上下文，按语义解决，不机械选择 ours/theirs。只暂存已解决文件，
然后运行 `git commit --no-edit`。worktree 模式下的所有冲突命令都在回执的 worktree 路径执行。
冲突需要产品决策或无法安全解决时保留现场并停止，不以部分 merge tree 交付审查。

## Checkout 验证

结构化准备回执已校验状态；之后漂移或旧 helper 才补充等价检查：

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git for-each-ref --format='%(upstream:short)' refs/heads/<selected-branch>
```

普通本地准备要求分支干净，分支名为 head 分支或 collision fallback，upstream 为
`<owner>/<head-branch>`，且 HEAD 等于 `headRefOid`。latest-base 后改为要求 remote head 和
frozen base 都是 HEAD 的 ancestor；如产生 merge commit，两个 parent 必须分别为该 head/base。

worktree 模式要求回执路径干净并位于对应 SHA；普通分支 tracking contributor，latest-base
分支保持 local-only。确认原 checkout 的分支、HEAD 和文件状态未变，后续命令以回执路径为 cwd。

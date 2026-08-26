# Git 工作流

本文只规定仓库 Git 状态保护、暂存和本地交付；请求语义和变更门禁分别见
[`request-boundary.md`](request-boundary.md) 与 [`execution-safety.md`](execution-safety.md)。

## 基本安全

- 保留用户现有的 staged 和 unstaged 变更，不重写或丢弃无关工作树内容。
- 除非任务明确授权、处于 `delivery` 模式或满足自动本地提交规则，否则不要暂存、提交
  或推送；明确禁止优先。
- 推送前必须将目标分支同步到最新远程状态；除非用户明确要求，任何模式都不执行
  `push`、`pull`、`rebase` 或 `merge`。
- 每个提交聚焦于一个连贯的行为或文档变更，并使用 Angular-style 信息。

## Git 交付顺序

1. 第一次写入前记录 `initial_head`、初始 staged、unstaged、untracked、冲突和任务允许路径。
2. `planning` 始终只读；初始索引非空、路径重叠、存在冲突、写入前检查失败或验证失败时进入 `protected`。
3. `delivery` 只处理用户明确授权的 staged diff，使用
   [`.agents/skills/git-commit/SKILL.md`](../../.agents/skills/git-commit/SKILL.md)，不自动扩大暂存范围。
4. `implementation` 在验证完成后，只有满足自动本地提交条件时才执行一次自动提交。

## 自动本地提交条件

以下条件必须同时满足：

- 任务是 `implementation`，且没有明确禁止提交；
- 初始索引为空，任务执行期间也没有出现新的非 Agent staged 内容；
- `HEAD` 未变化，当前索引无冲突，用户变更与 Agent 变更可以清晰分离；
- Agent 产生了仓库文件差异，并已创建或更新同任务 history；
- 允许路径和 Agent-owned paths 已明确，暂存后 staged paths 与预期集合完全一致；
- 必要验证已完成且没有阻塞性失败；
- 当前任务尚未执行过自动提交。

自动提交只暂存明确的 Agent-owned paths 和同任务 history，不使用 `git add .`。同一
任务分多轮实施时复用同一条 history；仅修改 history 的任务不递归创建第二条。没有
仓库文件差异时不创建空提交。

提交成功后，报告完整提交哈希、实际提交信息、工作树状态、push 状态，以及文本文件的
代码、文档和总变动统计；二进制变动不计入统计。

如果条件不满足，保留工作树并报告原因，不得提交。history 缺失时先补齐记录；如果
history 不在允许范围内或无法与用户变更分离，同样不得提交。

## Easydict PR 交付

需要创建 PR 时使用仓库现有的 `submit-pr` skill，并显式传入：

- `--base dev`
- `--base-remote origin`
- `--issue-policy forbid`

如果 head 需要推送到其他 fork remote，再显式传入 `--head-remote`。PR review 遵循
`.agents/skills/review-pr/SKILL.md` 的完整流程。

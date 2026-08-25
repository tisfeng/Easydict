# Git 工作流与本地交付

本文定义 Easydict 的 Git 安全边界和实现任务的本地交付方式。完整的提交信息、暂存
和提交后统计由 [git-commit skill](../../.agents/skills/git-commit/SKILL.md) 负责；
任务是否允许写入由 [`execution-safety.md`](execution-safety.md) 负责。

## 共同安全规则

- 保留用户现有的已暂存、未暂存和未跟踪变更；不重写或丢弃无关现场。
- 除非任务明确授权，任何模式都不执行 `push`、`pull`、`rebase` 或 `merge`。
- 不使用 `git add .`、宽泛 glob 或未核实路径的破坏性命令。
- 明确要求创建任务分支时，按照 git-commit skill 的 `Branch Name Guidance` 推导
  `<type>/<kebab-case-summary>`；除非用户指定，不添加 Agent、工具或个人命名空间。
- 推送前必须先核对目标分支的最新远程状态；没有明确推送授权时不推送。
- 每个提交聚焦于一个连贯的行为或文档变更。

## 任务模式与 Git

- `planning`：只读，不暂存、不提交、不推送；
- `delivery`：只处理用户明确授权的 staged diff，不自动扩大暂存范围，也不重新解释
  产品目标。
- `implementation`：完成验证后，在满足自动本地提交条件时执行一次自动提交。
- `protected`：初始索引非空、路径重叠、冲突或验证失败时保留现场，等待用户处理。

## 自动本地提交

实现任务只有同时满足以下条件才可自动本地提交：

- 当前模式是 `implementation`；
- `Mutation Gate` 已通过，且没有明确禁止自动提交的约束；
- 第一次写入前的初始暂存区为空，自动暂存前仍为空；
- 初始 `HEAD` 没有变化，当前索引没有冲突，暂存路径与预期集合完全一致；
- Agent 修改了产品代码、测试、构建配置、运行时资源或 Agent 文档；纯计划和历史
  文档变更本身不触发自动提交；
- Agent 路径与用户变更清晰分离且无冲突；
- 所有相关验证通过，且本任务尚未自动提交。

自动提交时只执行 `git add -- <精确路径>`，重新检查 staged diff，再调用 git-commit
skill 生成并校验 Angular-style 提交信息。自动提交不包含 push、pull、rebase、merge
或分支操作。提交成功后按 skill 要求报告完整哈希、实际提交信息、工作树状态、push
状态以及代码和文档统计。

## Easydict PR 交付

需要创建 PR 时使用仓库现有的 submit-pr skill，并显式传入：

- `--base dev`
- `--base-remote origin`
- `--issue-policy forbid`

如果 head 需要推送到其他 fork remote，再显式传入 `--head-remote`。submit-pr 负责
PR 创建和幂等检查，不负责 review、merge、Issue 关闭或截图生成；PR review 遵循
`.agents/skills/review-pr/SKILL.md`。

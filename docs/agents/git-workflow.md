# Git 工作流

本文只规定 Git 状态保护、暂存和本地交付。任务授权、首次快照和保护状态以
[`request-boundary.md`](request-boundary.md) 为准，plan/history 生命周期以
[`README.md`](README.md) 为准。

## 基本安全

- 保留用户已有的 staged、unstaged、untracked 和提交历史，不重写或丢弃无关内容。
- 未获得对应授权时，不暂存、提交、创建分支、集成或推送；明确禁止优先。
- implementation 默认只允许满足门禁后的本地自动提交，不自行扩大为 fetch、pull、push、
  rebase、merge、reset、stash 或 clean。
- PR、integration 和发布请求只执行对应 skill 明示且用户已授权的必要 Git 操作。
- 每个提交聚焦一个连贯变更，并使用 Angular-style 信息。

## 交付顺序

1. implementation 使用首次写入前冻结的 HEAD、索引、工作树、冲突、允许路径和内容归属
   判断交付安全；只读开始的显式 staged 交付或复用已有提交的 integration，在准备交付时建立
   同等内容的只读基线。
2. 完成最终审查和验证后按操作冻结交付范围：显式提交已有 staged 内容时冻结 staged paths
   与 staged raw patch；空索引且允许暂存的 commit 或 auto-local-commit 时，冻结
   `agent_owned_paths`，并把本任务实际产生且归 Agent 所有的每个改动路径逐一列入
   `expected_commit_paths`；这份清单不能遗漏上述路径，也不能包含用户原有改动或允许路径
   以外的文件；integration 复用已有提交时冻结对应提交范围。
3. 所有其他写入 Agent 结束后，串行委派
   [`.codex/agents/git-delivery.toml`](../../.codex/agents/git-delivery.toml)：
   `commit` 与 `auto-local-commit` 执行
   [git-commit](../../.agents/skills/git-commit/SKILL.md)，只有 `integration` 才执行
   [worktree-rebase-merge](../../.agents/skills/worktree-rebase-merge/SKILL.md)。委派输入还必须
   包含按实际 Skill 与用户范围冻结的 `staging_strategy`：`existing-index`、`explicit-paths`、
   `explicit-worktree-once` 或 `auto-exact`。
4. 需要创建提交时，`git-delivery` 先以 `prepare` 只读重验现场并返回精确提交信息草稿。
   主 Agent 在对话中原样展示“提交信息预览”后，同一 Agent 才能进入 `apply`；用户要求
   确认、仅预览或暂缓时必须等待批准。复用已有提交且无需新提交时不强制生成草稿。
5. 完成后，主 Agent 独立核验提交哈希、实际提交信息、分支、工作树、统计和未 push 状态。

`git-delivery` 的候选快照、精确暂存、prepare/apply 重验和校验不通过时停止交付的规则以
其受管 TOML 与所选 skill 为权威，本文不复制内部实现。配置、授权、模型、范围、HEAD、索引、冲突、目标
worktree 或验证不确定时进入 protected，不得改由主 Agent 或其他模型执行缩减版交付。

仅在本轮刚更新 `git-delivery` 配置且运行时尚不能重新发现时，主 Agent 才能读取 TOML，
以完全相同的模型、推理强度、写入权限和指令显式启动 bootstrap fallback，并在回执中说明；
无法精确复现时仍然 fail closed。

## 自动本地提交

以下条件必须同时满足：

- 任务是 implementation，且没有仍有效的禁止提交或暂缓交付要求。
- 初始索引为空，交付前没有出现新的非 Agent staged 内容。
- HEAD 未变化，索引无冲突，用户内容与 Agent 变更可以清晰分离。
- 最终存在仓库差异，并已满足 [`README.md`](README.md#plan-与-history) 的同任务 history
  要求。
- `expected_commit_paths` 逐一列出本任务产生的全部 Agent-owned 改动，不遗漏，也不包含用户
  原有或允许范围外的路径；暂存后只包含这些路径。
- 必要审查和验证覆盖最终快照，没有尚未解决且经核实的阻塞问题或失败验证。
- 当前任务尚未执行自动提交。

满足条件时，`git-delivery` 只精确暂存 expected commit paths 并执行一次本地提交，不使用
`git add .`。没有差异时不创建空提交。条件不满足时保留差异并报告原因，不得为满足提交条件
扩大授权或混入用户内容。

## 显式交付与集成

- 显式提交已有 staged 内容时以 staged raw patch 为唯一事实来源，不反向要求
  implementation history，也不套用自动提交的空索引前提。
- 已有 staged 内容超出用户指定范围时保留索引并报告，不自动调整或混入未暂存内容。
- 只有 integration 授权才允许 `worktree-rebase-merge` 所需的任务分支、临时 worktree、
  rebase 和 merge；commit 与 auto-local-commit 不包含这些动作。
- 已授权工作流需要任务分支名时，使用 `git-commit` skill 的 `Branch Name Guidance` 推导
  Conventional 分支名；该指南本身不授权创建分支。
- push 授权可以来自用户明确要求推送，也可以来自用户明确调用且按 skill 必然包含推送的 PR
  或发布工作流；执行前仍须核对远程目标和提交关系。

## 交付回执

提交成功后按 `git-commit` skill 报告完整哈希、实际提交信息、分支、提交后校验、最终工作树、
Push 状态，以及文本文件的总计/代码/文档变动统计。任何提交后校验或统计失败都不算完整交付，
不得编造结果。

## Easydict PR 参数

创建 PR 时使用 `submit-pr` skill，并显式传入：

- `--base dev`
- `--base-remote origin`
- `--issue-policy forbid`

当前受管 `submit-pr v0.3.2` 需要 Python 3.10 或更高版本。执行脚本或测试前确认解释器版本；
无法找到兼容解释器时 fail closed，不在项目内修改受管 Skill。需要推送到其他 fork remote 时
再显式传入 `--head-remote`。PR review 使用 `review-pr` skill。

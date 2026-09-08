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

1. 主 Agent 使用首次写入前冻结的 HEAD、索引、工作树、冲突、允许路径和内容归属判断
   交付授权及安全状态。
2. 完成最终审查和验证后按操作冻结交付范围：显式提交已有 staged 内容时冻结 staged paths
   与 staged raw patch；空索引且允许暂存的 commit 或 auto-local-commit 时，冻结
   `agent_owned_paths` 与 `expected_commit_paths`，两者实际差异集合相等，且 expected 全部
   属于允许路径；integration 复用已有提交时冻结对应提交范围。
3. 所有其他写入 Agent 结束后，串行委派
   [`.codex/agents/git-delivery.toml`](../../.codex/agents/git-delivery.toml)：
   `commit` 与 `auto-local-commit` 执行
   [git-commit](../../.agents/skills/git-commit/SKILL.md)，只有 `integration` 才执行
   [worktree-rebase-merge](../../.agents/skills/worktree-rebase-merge/SKILL.md)。
4. 需要创建提交时，`git-delivery` 先以 `prepare` 只读重验现场并返回精确提交信息草稿。
   主 Agent 在对话中原样展示“提交信息预览”后，同一 Agent 才能进入 `apply`；用户要求
   确认、仅预览或暂缓时必须等待批准。复用已有提交且无需新提交时不强制生成草稿。
5. 完成后，主 Agent 独立核验提交哈希、实际提交信息、分支、工作树、统计和未 push 状态。

`git-delivery` 的候选快照、精确暂存、prepare/apply 重验和失败关闭算法以其受管 TOML 与
所选 skill 为权威，本文不复制内部实现。配置、授权、模型、范围、HEAD、索引、冲突、目标
worktree 或验证不确定时进入 protected，不得改由主 Agent 或其他模型执行缩减版交付。

仅在本轮刚更新 `git-delivery` 配置且运行时尚不能重新发现时，主 Agent 才能读取 TOML，
以完全相同的模型、推理强度、写入权限和指令显式启动 bootstrap fallback，并在回执中说明；
无法精确复现时仍然 fail closed。

## 自动本地提交

以下条件必须同时满足：

- 任务是 implementation，且没有仍有效的禁止提交或暂缓交付要求。
- 初始索引为空，交付前没有出现新的非 Agent staged 内容。
- HEAD 未变化，索引无冲突，用户内容与 Agent 变更可以清晰分离。
- 最终存在仓库差异，同任务 history 已创建或更新。
- Agent-owned 实际差异与 expected commit paths 相等，expected 全部属于允许路径；暂存后
  staged paths 与 expected 完全一致。
- 必要审查和验证覆盖最终快照，没有有效阻塞 finding 或失败验证。
- 当前任务尚未执行自动提交。

满足条件时，`git-delivery` 只精确暂存 expected commit paths 并执行一次本地提交，不使用
`git add .`。没有差异时不创建空提交。条件不满足时保留差异并报告原因；缺少 history 时
先在允许范围内补齐，不能安全分离时不得暂存。

## 显式交付与集成

- 显式提交已有 staged 内容时以 staged raw patch 为唯一事实来源，不反向要求
  implementation history，也不套用自动提交的空索引前提。
- 已有 staged 内容超出用户指定范围时保留索引并报告，不自动调整或混入未暂存内容。
- 只有 integration 授权才允许 `worktree-rebase-merge` 所需的任务分支、临时 worktree、
  rebase 和 merge；commit 与 auto-local-commit 不包含这些动作。
- 已授权工作流需要任务分支名时，使用 `git-commit` skill 的 `Branch Name Guidance` 推导
  Conventional 分支名；该指南本身不授权创建分支。
- push 必须单独获得授权，并在执行前核对远程目标和提交关系。

## 交付回执

提交成功后按 `git-commit` skill 报告完整哈希、实际提交信息、分支、提交后校验、最终工作树、
Push 状态，以及文本文件的总计/代码/文档变动统计。任何提交后校验或统计失败都不算完整交付，
不得编造结果。

## Easydict PR 参数

创建 PR 时使用 `submit-pr` skill，并显式传入：

- `--base dev`
- `--base-remote origin`
- `--issue-policy forbid`

当前受管 `submit-pr v0.3.0` 需要 Python 3.10 或更高版本。执行脚本或测试前确认解释器版本；
无法找到兼容解释器时 fail closed，不在项目内修改受管 Skill。需要推送到其他 fork remote 时
再显式传入 `--head-remote`。PR review 使用 `review-pr` skill。

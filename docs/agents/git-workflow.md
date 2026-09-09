# Git 交付策略

本文只规定 Easydict 的 Git 交付授权、项目门禁、委派和 PR 参数。任务授权、首次快照及
`protected` 状态以 [`request-boundary.md`](request-boundary.md) 为准，plan/history 生命周期以
[`README.md`](README.md) 为准；暂存、提交、集成和回执的执行算法以受管 Skill 为准。

## 项目交付条件

- 保留用户已有的 staged、unstaged、untracked 和提交历史；没有对应授权时，不暂存、提交、
  创建分支、集成或推送，明确禁止优先。
- `implementation` 默认允许满足门禁后的 `auto-local-commit`，但不扩展为 fetch、pull、push、
  rebase、merge、reset、stash 或 clean。PR、integration 和发布只执行用户已授权且对应 Skill
  明示的 Git 操作。
- 自动本地提交还必须存在最终差异、满足同任务 history 要求，并有覆盖最终快照的必要审查和验证。
  主 Agent 冻结 `expected_commit_paths` 时，必须逐项覆盖本任务全部 Agent-owned 改动，不遗漏、
  不混入用户已有或允许范围外的路径；实际暂存与一次提交由
  [`git-commit`](../../.agents/skills/git-commit/SKILL.md#经仓库规则授权的自动交付) 执行。
- 自动交付条件不满足时保留差异并报告原因，不为满足条件扩大授权或混入用户内容；没有差异时不
  创建空提交。
- 显式 `commit` 的范围、已有 staged 内容与 `staging_strategy` 直接遵循
  [`git-commit`](../../.agents/skills/git-commit/SKILL.md#暂存决策)。自动交付的完整
  Agent-owned 路径要求不适用于显式路径或显式工作树提交。
- 只有 `integration` 授权才能运行
  [`worktree-rebase-merge`](../../.agents/skills/worktree-rebase-merge/SKILL.md) 所需的任务分支、
  临时 worktree、rebase 和 merge。push 必须由用户明确要求，或由已明确调用且必然包含 push 的
  PR/发布 Skill 授权。

## 委派与回退

所有其他写入完成后，主 Agent 串行委派
[`.codex/agents/git-delivery.toml`](../../.codex/agents/git-delivery.toml)。

| operation | 执行契约 |
| --- | --- |
| `commit` / `auto-local-commit` | [`git-commit`](../../.agents/skills/git-commit/SKILL.md) |
| `integration` | [`worktree-rebase-merge`](../../.agents/skills/worktree-rebase-merge/SKILL.md) |

- 主 Agent 传递已确认的授权、operation、初始快照、路径归属、冻结候选范围，以及由适用 Skill
  决定的 `staging_strategy`；不能由 git-delivery 扩大授权或范围。
- `prepare`/`apply` 重验、精确暂存和提交信息契约以 git-delivery TOML 与适用 Skill 为唯一
  执行依据。需要新提交时，主 Agent 必须原样展示 prepare 返回的完整提交信息预览；除非用户要求
  确认、仅预览或暂缓，同一执行者可以继续 apply。
- 主 Agent 独立核验执行结果，并完整呈现适用 Skill 的交付回执；不得将子代理的一行摘要当作完成。
- 配置、授权、模型、范围、快照、目标 worktree 或验证不确定时 fail closed，不得改由主 Agent
  或其他模型执行缩减流程。仅本轮刚更新 git-delivery 配置且运行时尚不能重新发现时，才可按相同
  模型、推理强度、写入权限和完整指令启动 bootstrap fallback，并在回执中说明；无法精确复现时
  仍然 fail closed。

## 提交 PR

- 使用 `submit-pr` Skill，默认合入 `dev`。
- 关联 Issue 时不使用自动关闭语法，Issue 是否关闭由维护者决定。

# Git 交付策略

本文只规定 Easydict 的 Git 交付授权、项目门禁、委派和提交 PR 约定。任务授权、首次快照及
`protected` 状态以 [`request-boundary.md`](request-boundary.md) 为准，plan/history 生命周期以
[`README.md`](README.md) 为准；暂存、提交、集成和回执的执行算法以受管 Skill 为准。

## 项目交付条件

- 保留用户已有的 staged、unstaged、untracked 和提交历史；没有对应授权时，不暂存、提交、
  创建分支、集成或推送，明确禁止优先。
- 交付授权按 [`request-boundary.md`](request-boundary.md#语义判定与任务状态) 确定；
  各工作流只执行用户已授权且对应 Skill 明示的 Git 操作。自动本地提交不要求新建分支；
  创建 PR 时使用任务分支。
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

- 委派优先使用 `fork_turns="none"`，传递已确认的授权与仍有效的限制、operation/phase、仓库和
  实际 Skill 路径、必要规则入口、初始及冻结快照、允许范围、路径归属与验证结果。不继承整段
  调查对话；子代理仍读取适用规则，同一轮已读且未变化的规则和证据可以复用。
- 需要新提交时，补齐精确候选和适用 Skill 决定的 `staging_strategy`；复用已有提交时，明确目标
  及允许集成的提交和路径限制。字段要求以实际加载的 git-delivery 与 Skill 契约为准，不能由
  执行者扩大授权或范围。
- 需要新提交时先执行只读 `prepare`，主 Agent 原样展示返回的完整提交信息预览，再由同一
  执行者按 `apply` 契约复验、暂存与提交。普通预览不是新的确认门槛；用户要求确认、仅预览、
  仅草稿或暂缓时，继续遵守相应的等待与写入限制。
- 已有提交的 `integration`，仅当实际加载的 git-delivery、`worktree-rebase-merge` Skill 及其
  配套检查脚本共同支持 `integrate`，且满足该 Skill 的一次委派条件时，使用 `phase=integrate`。
  同一执行者检查通过后继续集成，无需返回成功的 prepare 报告后再派 apply；无须暂存时按新版
  契约不传 `staging_strategy`。不重复展开 Skill 已规定的集中检查与阶段复验步骤。
- 完整的旧版资产继续遵循其 `prepare/apply` 和输入字段契约，不调用未安装的阶段或脚本。
  新版资产缺失或契约不一致时停止交付，不以旧流程掩盖安装异常；受管资产升级仍按
  [`README.md`](README.md#写入与同步) 执行。`integrate` 中需要新提交时按 Skill 返回
  `needs-prepare` 后转入提交预览流程；脏目标、范围不符、非预期漂移或冲突均保留现场并报告，
  不自行扩大为新提交、冲突修复或改变范围。
- 已知 Git 元数据或目标 worktree 位于受限写入路径时，直接为已授权命令申请最小必要提权，
  复用本轮已确认的权限边界，避免重复失败探测；权限审批仍逐操作适用，不将前次获批视为
  新增业务授权。审批拒绝时保留现场并报告受阻操作与原因。
- 执行者一次收集完整回执数据，实际提交信息、哈希与统计直接读取工具结果，不重新起草或翻译。
  主 Agent 批量独立核验后，按适用 Skill 的既有模板完整呈现全部字段、统计表和实际提交信息；
  不得将子代理的一行摘要当作完成。
- 配置、授权、模型、范围、快照、目标 worktree 或验证不确定时 fail closed，不得改由主 Agent
  或其他模型执行缩减流程。仅本轮刚更新 git-delivery 配置且运行时尚不能重新发现时，才可按相同
  模型、推理强度、写入权限和完整指令启动 bootstrap fallback，并在回执中说明；无法精确复现时
  仍然 fail closed。

## 提交 PR

- 使用 `submit-pr` Skill，默认合入 `dev`。
- 关联 Issue 时不使用自动关闭语法，Issue 是否关闭由维护者决定。

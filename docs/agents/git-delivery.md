# Git 交付策略

本文只规定 Easydict 的 Git 交付授权、项目门禁、执行和提交 PR 约定。任务授权、首次快照及
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
  [`git-commit`](../../.agents/skills/git-commit/SKILL.md) 执行。
- 自动交付条件不满足时保留差异并报告原因，不为满足条件扩大授权或混入用户内容；没有差异时不
  创建空提交。
- 显式 `commit` 的范围、已有 staged 内容与暂存方式直接交给
  [`git-commit`](../../.agents/skills/git-commit/SKILL.md) 判断。自动交付的完整 Agent-owned
  路径要求不适用于显式路径或显式工作树提交。
- 只有 `integration` 授权才能运行
  [`worktree-rebase-merge`](../../.agents/skills/worktree-rebase-merge/SKILL.md) 所需的任务分支、
  临时 worktree、rebase 和 merge。push 必须由用户明确要求，或由已明确调用且必然包含 push 的
  PR/发布 Skill 授权。

## 执行与回退

所有实现和其他写入 Agent 完成后，主 Agent 直接、串行执行获准的 Git 操作。

| 交付授权 | 执行契约 |
| --- | --- |
| `commit` / `auto-local-commit` | [`git-commit`](../../.agents/skills/git-commit/SKILL.md) |
| `integration` | [`worktree-rebase-merge`](../../.agents/skills/worktree-rebase-merge/SKILL.md) |

- 执行前读取实际 Skill。找不到对应 Skill、资产版本混合或宿主契约不一致时停止相关操作，不用
  旧版本、旧阶段或缩减流程掩盖安装异常；受管资产升级按 [`README.md`](README.md#写入与同步)。
- 运行时支持程序化工具调用时，可以合并正常成功路径的模型往返，并行无依赖只读检查，在同一
  程序中依次等待已获准的独立命令。每条 Git 命令仍使用独立工具调用和权限边界；只有明确完成且
  退出码为 `0` 才能继续，运行中会话、缺少退出码、审批未完成或非零退出都不是成功。
- 需要新提交时，把提交任务、允许范围和已有证据交给 `git-commit`，由其完成范围判断、预览、
  暂存、提交和校验；普通预览不是新的确认门槛，用户要求确认、仅预览、仅草稿或暂缓时继续
  等待。复用已有提交时不重新起草提交信息。
- 同一内容快照上已核验的授权、范围、审查、验证和仓库元数据可以复用。Git 写入前仍复验相关
  HEAD、索引、工作树、冲突和允许范围；非预期变化使相关证据失效时保留现场并停止对应操作。
- `integration` 需要新提交时由 `git-commit` 完成获准提交；源提交已经存在且源工作树干净时，
  直接按 `worktree-rebase-merge` 继续，不制造额外预览往返。脏目标、范围不符、非预期漂移或
  冲突均按该 Skill 保留现场，不自行扩大为新提交、冲突修复或改变范围。
- 已知 Git 元数据或目标 worktree 位于受限写入路径时，直接为已授权命令申请最小必要提权，
  复用本轮已确认的权限边界，避免重复失败探测；权限审批仍逐操作适用，不将前次获批视为
  新增业务授权。审批拒绝时保留现场并报告受阻操作与原因。
- 主 Agent 一次收集并核验完整回执。实际提交信息、完整哈希、分支、工作树、push 状态和统计
  直接读取 Git 与 Skill 结果，不重新起草、翻译或重复收集。首次完整 raw patch 仍用于语义
  审核；后续未变化事实使用冻结内容证据紧凑复验，不能用摘要替代 staged 等价检查。
- 配置、授权、范围、快照、目标 worktree 或验证不确定时 fail closed，不执行缩减流程。

## 提交 PR

- 使用 `submit-pr` Skill，默认合入 `dev`。
- PR 标题、正文、预览和最终报告按显式偏好、当前对话、系统首选语言的顺序确定用户语言；仓库
  有独立硬性语言要求且与显式偏好冲突时停止并请求决定，不根据英文模板或终端 locale 改写偏好。
- 关联 Issue 时显式使用 `forbid` 策略，不使用自动关闭语法；Issue 是否关闭由维护者决定。
- `submit-pr` helper 成功且 `pr_verification.status == "passed"` 时直接复用其最终验证字段，不重复
  读取完整 PR 正文。默认不等待 CI；只有用户或仓库规则明确要求时才查询或等待 checks。

---
name: review-pr
description: 审查 GitHub PR 的准确 head/base diff、关联 issue、CI 和 review threads；明确调用时回复并关闭已解决线程，交付前刷新。创建 PR 使用 submit-pr；本地审查使用 review。
---

# GitHub PR 审查

本 Skill 编排 GitHub PR 的身份、问题背景、本地准备、CI、线程和最终刷新。
语义与正确性审查使用配套 `review`；审查本地工作树、提交、范围、文件或模块时直接使用
`review`，不启动 PR 编排。

`<review-pr-skill-dir>` 指实际加载的本 Skill 目录。优先从当前 Skill 清单定位 `review`，
未提供位置时才检查 [同级安装位置](../review/SKILL.md)。开始 Git 准备前确认依赖可读；
缺失时可收集获准的只读证据，但不得声称完整代码审查已完成。

审查分支命名依赖同级完整安装的 `git-commit`，只使用其
[统一命名规范与工具](../git-commit/references/branch-naming.md)；缺失时不执行本地 Git 准备，可继续远程证据审查。

## 模式与授权

- **默认本地审查**：明确请求审查 PR 时，包含必要的 remote 添加、fetch、安全分支创建或
  fast-forward、upstream 设置和 checkout。
- **隔离 worktree**：只在用户明确要求 worktree、并行或并发 review 时新建；已关联的 PR 同名分支
  已在其他 worktree 打开时可复用其干净 checkout，后续命令使用回执路径。
- **latest-base 集成审查**：只在用户明确要求更新最新 base、解决冲突或审查集成结果时使用。
- **不改变 Git 状态**：遵守用户的只读或不切分支限制，改用可访问的准确远程 diff、源码和评论；
  证据不足时报告限制。

明确调用本 Skill 审查 PR 时，默认包含检查全部开放线程，并对确认已修复或不再适用的线程
回复依据后 resolve；该评论维护授权不需要逐条重复确认。用户只读、仅方案、禁止评论或
限制远程操作时遵守其限制，只检查和报告。隐式选用本 Skill 不自行扩大发布回复的授权；
按已有任务授权执行。其他产品修复、push、发布独立评论、approve、删除评论或关闭 PR
仍不包含在上述授权中。仅方案或解释不执行 Git 准备。

## 核心安全边界

- 默认本地模式从 `git status --short --branch` 开始；当前 checkout 有未提交变更时，
  在切换分支前停止。显式 worktree 模式不得改变原 checkout，因此可从脏状态继续。
- 多阶段 review 必须把首次准备回执中的 `checkout.branch` 作为后续阶段的显式输入；使用
  helper 的 `--reuse-branch` 复验该分支、HEAD、upstream 和 worktree 占用，失败时停止，
  不静默改选另一个分支。回执记录实际 helper 路径、入口 SHA 和准备依赖组合指纹，
  按本地准备协议复验版本漂移。
- 不覆盖、删除、重命名、rebase、reset、强制更新、stash 或丢弃本地分支、worktree 或变更。
- 普通审查必须对应 PR 元数据的准确 `headRefOid` 和真实 base/merge-base diff；
  不用 detached HEAD、已 fetch ref 或无关 `origin` 绕过身份检查。
- 本地同名分支的 upstream 指向准确 PR head 仓库与分支时，直接复用，不受 PR 作者身份
  或 remote 别名限制。相同或落后的分支安全准备到远程 head；领先时保留额外提交，按冻结
  Git 对象审查；分叉时停止，不另建 review 分支绕过。没有同名分支时创建并校验准确 upstream。
  回执区分 checkout 与 review SHA；源码和验证归属遵循 [证据协议](references/evidence-workflow.md)。
  未关联或 upstream 不匹配时按本地准备协议处理，不覆盖原关联。
- `mergeable: CONFLICTING`、`mergeStateStatus: DIRTY` 或 base 领先不构成 latest-base 授权。
- 除非用户明确要求，审查、准备、冲突处理和线程维护都不 push。审查后保留准备好的
  分支或 worktree，不自动删除。

## 审查流程

1. 读取 [证据收集与刷新](references/evidence-workflow.md)，收集并冻结 PR 身份、head/base、
   [问题背景](references/problem-review.md)、checks 和完整 threads/replies。
2. 允许 Git 准备时读取 [本地准备与 latest-base](references/local-preparation.md)；只读模式直接使用准确远程证据。
3. 将 PR 目标、关键验收条件、冻结 base/head 和完整 raw diff 交给 `review`，检查需求满足程度、
   实现方式与代码正确性。
4. 评估每个开放 thread，包括 outdated、bot 和所有回复。已有评论只放在对应评论条目，
   不重复列为独立 finding。读取 [线程维护](references/thread-resolution.md) 判定是否已修复或
   不再适用；在授权范围内先回复依据、确认成功后 resolve，仍有效或证据不足则保持开放。
5. 如任务包含冲突处理、验证或本地提交，先完成这些获准操作；结论前按证据协议立即刷新 PR、
   选定问题证据、checks 和完整 threads/replies，处理所有新活动。
6. 生成最终回复前重新读取 [PR 审查报告](references/reporting.md)；此前已读过或上下文摘要中
   提及过，均不替代此次读取。按该协议组织报告与必要的提交回执，并对实际回复草稿完成
   [交付检查](references/reporting.md#交付检查) 后再输出。

大 PR 或需要复用快照文件时才读取
[快照传输协议](references/snapshot-protocol.md)；复杂复审报告可再读取 [完整示例](references/report-example.md)。

## 完成与停止条件

只有准确 remote head/base 与 merge-base、完整 diff、目标/问题证据、CI 状态、全部开放 threads
及回复均已审查，最终刷新没有未检查活动，且最终报告通过交付检查时，才算完成。最终刷新发现 head/base、
需求或线程变化时，根据影响更新 checkout、范围和判断，处理后再刷新一次。

引用有歧义、准备会覆盖本地状态、依赖或必需证据不可用、身份/内容持续漂移、冲突需要产品判断，
或最终刷新失败时，保留当前快照和本地状态，报告已审查 SHA 与未覆盖缺口；不无限重试。
受阻或未完成报告仍遵循报告协议，保留内容介绍及验证限制；证据不足的字段明确标注缺失，
不为满足格式编造内容，也不将报告格式完整视为审查已完成。

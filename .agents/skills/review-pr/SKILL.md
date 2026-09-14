---
name: review-pr
description: 审查 GitHub PR 的准确 head/base diff、关联 issue、CI 和 review threads，交付前刷新。创建 PR 使用 submit-pr；本地审查使用 review。
---

# GitHub PR 审查

本 Skill 编排 GitHub PR 的身份、问题背景、本地准备、CI、线程和最终刷新。
语义与正确性审查使用配套 `review`；审查本地工作树、提交、范围、文件或模块时直接使用
`review`，不启动 PR 编排。

`<review-pr-skill-dir>` 指实际加载的本 Skill 目录。优先从当前 Skill 清单定位 `review`，
未提供位置时才检查 [同级安装位置](../review/SKILL.md)。开始 Git 准备前确认依赖可读；
缺失时可收集获准的只读证据，但不得声称完整代码审查已完成。

## 模式与授权

- **默认本地审查**：明确请求审查 PR 时，包含必要的 remote 添加、fetch、安全分支创建或
  fast-forward、upstream 设置和 checkout。
- **隔离 worktree**：只在用户明确要求 worktree、并行或并发 review 时使用。
- **latest-base 集成审查**：只在用户明确要求更新最新 base、解决冲突或审查集成结果时使用。
- **不改变 Git 状态**：遵守用户的只读或不切分支限制，改用可访问的准确远程 diff、源码和评论；
  证据不足时报告限制。

上述本地准备授权不包含产品修复、push、发布评论、approve、删除评论或关闭 PR。
线程 resolve 需要单独的远程操作授权和当前远程证据。仅方案或解释不执行 Git 准备。

## 核心安全边界

- 默认本地模式从 `git status --short --branch` 开始；当前 checkout 有未提交变更时，
  在切换分支前停止。显式 worktree 模式不得改变原 checkout，因此可从脏状态继续。
- 不覆盖、删除、重命名、rebase、reset、强制更新、stash 或丢弃本地分支、worktree 或变更。
- 普通审查必须对应 PR 元数据的准确 `headRefOid` 和真实 base/merge-base diff；
  不用 detached HEAD、已 fetch ref 或无关 `origin` 绕过身份检查。
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
   不重复列为独立 finding。需要 resolve 且已获授权时才读取
   [线程维护](references/thread-resolution.md)。
5. 结论前按证据协议立即刷新 PR、选定问题证据、checks 和完整 threads/replies，处理所有新活动。
6. 读取 [PR 审查报告](references/reporting.md)，输出结论、有效问题、线程状态、审查范围和验证。

大 PR 或需要复用快照文件时才读取
[快照传输协议](references/snapshot-protocol.md)；复杂复审报告可再读取 [完整示例](references/report-example.md)。

## 完成与停止条件

只有准确 remote head/base 与 merge-base、完整 diff、目标/问题证据、CI 状态、全部开放 threads
及回复均已审查，且最终刷新没有未检查活动时，才算完成。最终刷新发现 head/base、
需求或线程变化时，根据影响更新 checkout、范围和判断，处理后再刷新一次。

引用有歧义、准备会覆盖本地状态、依赖或必需证据不可用、身份/内容持续漂移、冲突需要产品判断，
或最终刷新失败时，保留当前快照和本地状态，报告已审查 SHA 与未覆盖缺口；不无限重试。

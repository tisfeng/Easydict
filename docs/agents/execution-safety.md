# 执行安全与 Mutation Gate

本文定义 Agent 何时可以写入工作树，以及如何把用户请求收敛为可审计的任务契约。
请求语义见 [`request-boundary.md`](request-boundary.md)，Git 交付见
[`git-workflow.md`](git-workflow.md)。

## 基本原则

- 先确定任务模式，再确定允许动作和允许路径；工具能力不等于用户授权。
- 任何写入都必须能对应到用户目标、任务契约或完成检查。
- 只读请求默认不写入、不暂存、不提交、不推送。
- 维护已有工作树边界，不重写、丢弃或覆盖与当前任务无关的变更。
- 优先采用满足目标的最小方案，避免推测性功能和单次使用的抽象。
- 低风险、可逆、在目标仓库范围内的实现步骤可以直接执行；外部服务、推送、删除
  和其他扩大范围的动作需要明确授权。
- 交付前完成与风险相称的验证；遇到阻塞时明确报告证据和未验证边界。

## 任务契约

在调用会修改工作树、外部服务或交付物的工具前，内部确定以下字段：

- `Goal`：用户真正想得到的结果。
- `Requested operations`：用户明确允许的操作。
- `Mutation authorization`：分别记录 worktree、artifact 和 external service 是否获准
  写入。
- `Delivery authorization`：分别记录 `none`、`auto-local-commit`、`commit`、
  `integration` 或 `push`。
- `Allowed paths`：允许修改的精确文件或目录。
- `Forbidden actions`：明确不执行的动作，例如产品代码、Xcode 工程、推送或删除。
- `Evidence inputs`：引用提交、附件、当前 checkout 和仓库文档等证据来源。
- `Adopted constraints`：采用的仓库规则、用户限定和兼容性要求。
- `Ambiguities`：可能改变范围或结果的未决问题。
- `Deliverables`：用户要求看到的代码、文档、报告或提交。
- `Checks`：完成前必须执行的验证。

## Mutation Gate

任何变更工具调用前生成一次以下门禁结果：

```text
Mutation Gate: PASS | BLOCKED
```

只有以下条件全部满足时才允许 `PASS`：

- 完整请求语义明确授权 Agent 造成当前类型的状态变化。
- 目标、条件、指代和允许路径已经确定，且没有未决歧义。
- 没有否定约束、来源冲突或未满足的条件。
- 已记录初始 `HEAD`、staged、unstaged、untracked 和 conflicts 状态。
- Agent-owned 路径与用户已有变更不重叠。
- 当前工具调用属于任务契约中的 Mutation authorization 和 Allowed actions。

`planning`、授权不明确或门禁条件不完整时必须保持 `BLOCKED`。`planning` 可以阅读、
搜索、检查、诊断、比较、起草方案和报告结论，但不写入工作树、计划或其他 artifact；
保存计划文件也属于 artifact mutation，不能作为 planning 的隐含例外。只有用户明确
授权 `implementation` 后，才允许在范围内创建 active 计划并写入实现文件。Mutation
Gate 是仓库流程门禁，不等同于宿主运行时权限；需要技术保护时，还应使用通过门禁后
限定路径的 scoped-write capability，并限制暂存、提交和单次交付计数。

## 保护状态

以下任一情况都进入 `protected`：

- 初始暂存区已有文件；
- 用户已有变更与 Agent 允许路径重叠，无法清晰分离；
- 工作树存在冲突；
- Mutation Gate 失败；
- 必要验证失败或无法区分失败是否由本次变更引起；
- 用户要求的外部授权尚未获得。

进入保护状态后，保留当前现场，报告证据、影响和需要用户决定的下一步；不得用
`git reset --hard`、`git checkout --` 或其他破坏性操作“清理”现场。

## 执行顺序

1. 读取入口、任务相关规则和必要的架构文档。
2. 对多步骤、跨模块或高风险工作，先在当前回复中形成执行计划；planning 阶段不将
   计划写入仓库文件。
3. 形成任务契约和成功标准，检查工作树并执行 Mutation Gate。
4. 只有在获准的 implementation 中，才按
   [`documentation-governance.md`](documentation-governance.md) 创建 active 计划。
5. 以最小切片修改允许路径，避免顺手重构或扩大范围。
6. 运行与变更风险相称的格式、静态、构建或行为验证。
7. 复核 diff、路径、未验证边界和交付授权。
8. 按 [`documentation-governance.md`](documentation-governance.md) 完成计划和历史，
   按 [`git-workflow.md`](git-workflow.md) 完成本地交付。

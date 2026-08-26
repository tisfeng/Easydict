# 执行安全与变更门禁

本文规定 Agent 何时可以改变工作树或其他获准 artifact，以及何时必须停止；请求模式见
[`request-boundary.md`](request-boundary.md)，Git 状态和交付见
[`git-workflow.md`](git-workflow.md)，计划与 history 生命周期见 [`README.md`](README.md)。

## 核心规则

- `planning` 只允许读取、搜索、检查、诊断、起草和报告，不写入工作树或 artifact。
- `implementation` 必须有明确的实施授权，并且只修改任务允许的路径。
- 保留用户已有的 staged、unstaged 和 untracked 变更，不覆盖无关内容。
- 变更前后都使用满足风险的验证；没有实际验证的结果必须明确标注为未验证。
- 预期产生仓库文件差异的 implementation 必须创建或更新同任务 history；没有文件差异时不创建空 history。

## 写入前检查

第一次写入前，用以下五个问题确认范围：

1. 用户是否明确授权本次类型的写入？
2. 目标结果和允许修改的路径是否明确？
3. 初始 Git 状态是否允许安全区分 Agent 变更与用户变更？
4. 是否已确定必要的 history，以及多步骤或高风险工作所需的 active plan？
5. 完成后要运行哪些检查，哪些检查无法运行？

五项都满足时，写入前检查通过（`Mutation Gate`）；否则保持只读并报告原因。

## 执行流程

1. 根据完整请求确定任务模式、交付授权和安全状态。
2. 在第一次写入前记录 Git 快照、任务范围和 Agent-owned paths，并完成写入前检查。
3. 只实施获准路径，按风险完成验证；文件有差异时同步更新 history。
4. 验证通过后交给 Git 工作流处理交付；不把执行授权扩大为 push、pull、rebase 或 merge。

## 必须暂停的情况

出现以下任一情况，进入 `protected`，保留现场，不继续写入、暂存或提交：

- 初始索引非空、存在冲突，或 Agent 路径与用户变更重叠；
- 用户授权、目标、路径或必要条件仍不明确；
- 写入前检查未通过；
- 必要验证失败，或无法区分已验证与未验证的结论；
- history 不在允许范围内，或交付前缺少同任务 history。

`protected` 只是暂停保护现场，不代表用户已经授权额外操作，也不能把 planning 变成
implementation。

## 规则归属

- 请求来源、否定条件和任务模式由 [`request-boundary.md`](request-boundary.md) 负责。
- Git 快照、精确暂存、自动本地提交和禁止的远程操作由 [`git-workflow.md`](git-workflow.md) 负责。
- active plan、completed plan 和 history 的生命周期由 [`README.md`](README.md) 负责。

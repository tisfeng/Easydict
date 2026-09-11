# 审查规则

本文规定项目的实质审查门禁与审查快照。审查方法和 GitHub PR 上下文分别由
[`review`](../../.agents/skills/review/SKILL.md) 与
[`review-pr`](../../.agents/skills/review-pr/SKILL.md) Skill 规定；请求授权与通用回退见
[`request-boundary.md`](request-boundary.md)。

## 审查门禁

- 主 Agent 按对应 Skill 执行实质代码、配置或文档审查，包括本地任务变更、工作树、
  提交/range、文件、模块、GitHub PR 和复审；调用 `review` 或 `review-pr` 同样适用。
- 有行为风险的 implementation 在收尾阶段完成同样的审查；简单文档、低风险配置或小改动
  可只完成必要检查。
- 仅查询 CI、列举线程、解释已有报告或讨论审查流程，不因涉及 review 字样触发本规则。
- 审查默认只读，不修改文件、Git 状态或外部服务。主 Agent 不把自审写成独立审查；用户明确
  要求独立评审时如实报告该限制，不据此扩大授权。

## 快照与复用

- 主 Agent 冻结待审快照并传递基线、范围和必要上下文；本地审查可使用内容快照，PR 必须绑定
  准确 head/base，并包含身份一致的 PR 元数据、完整分页 threads/replies 和 checks。
- PR 的准备、远程线程操作、CI 获取和最终刷新由主 Agent 编排。优先使用 `review` 与
  `review-pr` 的稳定快照 helper；helper 不可用时，手动回退必须保持相同证据范围，并在 checks
  查询后复验 head，不能绕过 helper 已发现的漂移。
- 同一内容快照的有效审查结论可以在后续实施和交付阶段复用，不因工作流阶段变化重复审查。
  影响结论的代码或上下文变化后，只复核受影响范围，确保最终结论覆盖最终快照。
- 最终刷新仍重新完整读取可变远程状态；fingerprint 只压缩未变化结果的输出，不表示跳过刷新。
  head、thread、reply 或 checks 变化时重新审查受影响证据，默认不等待 pending CI。

## 审查结论

- 主 Agent 核验审查意见，在已有授权内修复真实问题；无依据或超范围建议说明原因。实现变化后
  按风险进行必要复核，最终采用的审查和验证必须覆盖最终快照。
- 单独 review 默认只读；审查、planning 或 staged 提交不会自动升级为修复任务。

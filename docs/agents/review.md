# 审查规则

本文规定项目的实质审查门禁、reviewer 职责与审查快照。审查方法和 GitHub PR 上下文分别由
[`review`](../../.agents/skills/review/SKILL.md) 与
[`review-pr`](../../.agents/skills/review-pr/SKILL.md) Skill 规定；请求授权与通用回退见
[`request-boundary.md`](request-boundary.md)。

## Reviewer 委派

- 主 Agent 执行实质代码、配置或文档审查时，必须委派只读 `reviewer` 并等待结果，包括本地
  任务变更、工作树、提交/range、文件、模块、GitHub PR 和复审；调用 `review` 或 `review-pr`
  执行审查同样适用。
- 未进入上述实质审查流程时，有行为风险的 implementation 优先使用只读 `reviewer`；简单文档、
  低风险配置或小改动可由主 Agent 完成必要检查。
- 仅查询 CI、列举线程、解释已有报告或讨论审查流程，不因涉及 review 字样触发本规则。
- 委派使用 `.codex/agents/reviewer.toml`。reviewer 只读，不修改文件、Git 状态或外部服务，
  也不递归委派。

## 快照与协作

- 主 Agent 冻结待审快照并传递基线、范围和必要上下文；本地审查可使用内容快照，PR 必须绑定
  准确 head/base。
- PR 的准备、远程线程操作、CI 获取和最终刷新由主 Agent 编排，reviewer 返回绑定该快照的
  审查结果。
- 影响结论的代码或上下文变化后，主 Agent 委派 reviewer 增量复核，确保结论覆盖最终快照。

## 结论与回退

- 主 Agent 核验审查意见，在已有授权内修复真实问题；无依据或超范围建议说明原因。实现变化后
  按风险进行必要复核，最终采用的审查和验证必须覆盖最终快照。
- 必需的 reviewer 未返回时，不得宣称独立审查或本轮必需审查已完成；无法委派时按
  [`request-boundary.md`](request-boundary.md#子代理委派与回退) 回退，并明确标注
  “未完成独立 reviewer 复核”。
- 单独 review 默认只读；审查、planning 或 staged 提交不会自动升级为修复任务。

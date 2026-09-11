# 设计文档

本目录统一保存 Easydict 的产品与技术设计，以及需要长期维护的设计决策。当前 Agent 执行规则
仍以根 `AGENTS.md` 和 `docs/agents/` 为权威；任务进度和完成结果分别位于
`docs/exec-plans/` 与 `docs/histories/`。

## 产品与技术设计

- [`application-architecture.md`](application-architecture.md)：当前源码布局、运行时边界和
  验证入口。
- [`select-text-flow.md`](select-text-flow.md)：文本选择的回退流程。

## Agent 与仓库治理

- [`agent-documentation-structure.md`](agent-documentation-structure.md)：Agent 文档入口、知识
  分层和维护边界的设计理由。
- [`external-agent-assets-management.md`](external-agent-assets-management.md)：外部 Skills、
  第三方 Skill 与项目专属 Skill 的版本治理理由。

产品与技术设计随实现更新；长期设计决策保留状态、日期、背景、取舍和重新评估条件。本目录
不保存任务日志或公共使用说明，也不作为第二套 Agent 任务路由。

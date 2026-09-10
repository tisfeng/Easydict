# Reviewer 委派边界

- 日期：2026-09-09
- 状态：completed
- 关联计划：[`2026-09-09-reviewer-delegation.md`](../../exec-plans/completed/2026-09-09-reviewer-delegation.md)

## 用户请求

执行 reviewer 委派改进方案，并明确区分 planner 与 reviewer。

## 变更

- 在 `AGENTS.md` 提供统一 review 路由入口，并将具体 reviewer 委派规则集中到
  `docs/agents/build-and-test.md`。
- 将实质代码、配置、文档、本地、PR 与复审纳入 reviewer 委派和等待门禁；明确非实质查询例外、
  最终快照增量复核及无法委派时的报告要求。
- 在 `request-boundary.md` 保留 planner 的独立方案规划边界，并明确它不能替代 reviewer。

## 设计意图

保留 planner 的方案职责，将实质审查的独立复核固定为 reviewer 的职责，并让主 Agent 保有 PR
上下文、线程、CI 和最终刷新的编排责任。

## 验证

- `git diff --check`：通过。
- 相对链接与角色边界：静态检查通过。
- 独立 reviewer：未发现需要修复的 finding；审核的是冻结 HEAD 加本任务未提交差异的快照。
- 未运行 `xcodebuild`，因为本次仅修改治理 Markdown。

## 受影响文件

- `AGENTS.md`
- `docs/agents/request-boundary.md`
- `docs/agents/build-and-test.md`
- `docs/exec-plans/completed/2026-09-09-reviewer-delegation.md`

## 后续事项

- None

# 保持一次性 Agent 文档检查器移除状态

- 日期：2026-08-21
- 状态：completed
- 关联变更：`2026-08-21-agent-request-boundary.md`

## 原因

Easydict 已通过 `0d21681c8` 移除一次性 Agent 文档检查器。该脚本只验证文档结构，
不能直接验证 Agent 是否正确处理附件中的指令；重新引入会与当前仓库治理方向冲突。

## 变更

- 保持 `scripts/check-agent-docs.sh`、`scripts/new-exec-plan.sh` 和
  `scripts/new-history.sh` 不存在。
- 不新增与请求边界相关的一次性 checker 或 fixture。
- 保留请求来源、自动任务契约、任务模式和 skill 边界规则。

## 验证

- 确认现行 `docs/agents/` 和 `docs/exec-plans/templates/` 没有引用已删除的检查器。
- 保留历史计划和历史记录中的事实性记录，不将历史命令当作当前工作流。
- 未运行 `xcodebuild`，因为本次只修改 Agent 文档和 skill。

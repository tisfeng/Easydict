# 明确 Planner 委派决策

## 状态

已完成

## 用户目标

将 Scoco 的 Planner 委派决策改进移植到 Easydict 的项目自有治理规则。

## 初始快照

- HEAD：`0f81a45a2845e948dc577a57f9eb23abc6b4f570`
- 分支：`dev`
- 工作树：干净

## 计划

见[执行计划](../../exec-plans/completed/2026-09-09-clarify-planner-delegation.md)。

## 已完成内容

- 在 `AGENTS.md` 增加入口提醒：每项任务应按 `Planner 委派决策` 判断是否使用子代理。
- 在 `docs/agents/request-boundary.md` 建立唯一的决策表，将任务模式与 Planner 委派拆开；发布、
  部署、外部服务写入、跨系统实际取舍和不可逆或高风险操作必须先获得独立规划结论。
- 发布示例适配 Easydict 的 GitHub Release 与 appcast 更新；低风险单模块查询或说明保留直接处理路径。
- 不修改受 lock 管理的 Skills、子代理 TOML 或 lock；不执行发布、推送或应用构建。

## 验证记录

- 独立 reviewer 未发现 P1/P2/P3，确认 PR inline thread resolve 权限与 `#子代理委派与回退` 锚点保持有效。
- `git diff --check` 通过；人工核验发布方案触发、发布参数解释不触发、跨系统实际取舍触发、低风险
  单模块查询不触发，以及禁止委派或配置不可用时的披露边界。
- 未运行 Xcode：仅修改治理 Markdown，未涉及产品或测试代码。

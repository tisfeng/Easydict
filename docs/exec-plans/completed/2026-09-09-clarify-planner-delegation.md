# 明确 Planner 委派决策

- 状态：completed
- 创建日期：2026-09-09
- 负责人：Codex
- 关联 Issue/PR：none

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 目标结果：将 Planner 委派条件从笼统描述改为可执行的唯一决策表。
- 允许修改路径：`AGENTS.md`、`docs/agents/request-boundary.md`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-09-clarify-planner-delegation.md`
- 禁止动作：不修改 `.codex/agents/`、`.agents/skills/`、lock、产品代码、外部服务或 Git remote。

## 初始快照与门禁

- 写入前检查：pass
- 初始 HEAD：`0f81a45a2845e948dc577a57f9eb23abc6b4f570`
- 初始 staged、unstaged、untracked 路径：none
- 初始冲突：none
- Agent-owned paths：允许修改路径中的四个文件。

## 目标与非目标

### 目标

- 明确 `intent_mode` 与 Planner 委派是独立判断。
- 定义发布、部署、外部写入、跨系统取舍与高风险操作的必需委派条件。
- 保留低风险单模块查询或说明的直接处理路径，以及用户禁止委派或配置不可用时的如实披露。

### 非目标

- 不修改 `planner.toml`、installer、受管 Skills 或 lock。
- 不改变 reviewer、tester 或 Git 交付的职责。
- 不执行发布、推送或应用构建。

## 工作计划

1. 更新入口提醒，并在请求边界中建立唯一的 Planner 决策表。
2. 删除旧的重复判定，保留现有子代理回退和其他角色规则。
3. 检查 Markdown、链接、锚点和规则语义，归档本计划并完成 history 与本地交付。

## 风险与验证

- 风险：将所有 planning 强制委派会增加简单查询的等待；因此只对实际需要独立取舍的目标强制触发。
- 验证：`git diff --check` 通过；相对链接、锚点和规则场景人工核验通过；独立 reviewer 未发现
  P1/P2/P3 finding。
- 未运行 Xcode：仅修改治理 Markdown，未涉及产品或测试代码。

## 完成条件

- [x] 入口只提示决策，不复制专题规则。
- [x] 请求边界含可执行决策表，且没有旧规则重复。
- [x] history、验证与本地提交完成。

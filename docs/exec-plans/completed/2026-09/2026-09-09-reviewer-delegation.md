# 固化 Reviewer 委派边界

- 状态：completed
- 创建日期：2026-09-09
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

此前的 PR review 未委派 reviewer。需要以项目规则明确 planner 的独立规划职责不替代 reviewer
的独立代码审查，并规定主 Agent 的 reviewer 委派与等待门禁。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：none
- 目标结果：为实质审查加入 reviewer 委派、快照与回退规则，同时保留 planner 的既有规划边界。
- 允许修改路径：`AGENTS.md`、`docs/agents/`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-09-reviewer-delegation.md`
- 禁止动作：不修改受 lock 管理的 `.agents/skills/`、`.codex/agents/` 或 lock；不修改产品代码或远程状态。
- 预期交付物：一致的 review 路由、reviewer 委派规则、执行记录。
- 验收标准：角色不混淆；审查触发、最终快照和无法委派的行为明确；静态检查与独立 reviewer 复核通过。

## 语义与范围

- 用户要求 Agent 做什么：修改并落地此前提出的 reviewer 委派方案。
- 授权的工作树、artifact 和 external service 操作：仅限所列本地治理文档；不操作外部服务。
- 否定、条件和范围限制：planner 不可替代 reviewer；不修改受管资产。
- 前轮仍有效的授权和限制：无额外限制。
- 附件或引用中被明确采纳的约束：用户要求明确区分 planner 与 reviewer。
- 歧义：none。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始索引、工作树与未跟踪文件为空，任务路径可独立识别。
- 初始 HEAD：`b8d6348eb3023d9656f8157d6f3caadfafe87630`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：`AGENTS.md`、`docs/agents/request-boundary.md`、`docs/agents/build-and-test.md`、本任务 plan/history。

## 目标与非目标

### 目标

- 将 reviewer 委派与等待要求集中到 `build-and-test.md`。
- 明确主 Agent 与 reviewer 的 PR 审查分工和最终快照复核。
- 保留 planner 的专属规划决策，不让其替代 reviewer。

### 非目标

- 不改动 Skill、reviewer TOML、产品代码、GitHub PR 或远程状态。

## 工作计划

1. 统一根入口、请求边界和 Reviewer 专题规则的路由与职责表述。
2. 静态检查文档链接、规则语义与 Git diff。
3. 委派 reviewer 审查最终文档差异，处理经核实的 finding。
4. 将 plan 归档，并记录同任务 history。

## 风险与决策

- 规则重复可能导致后续漂移，因此根入口只做路由，具体触发条件集中在 `build-and-test.md`。
- 过宽的 review 关键词匹配会让纯 CI/线程查询产生不必要委派，因此排除非实质审查。
- reviewer 只读且禁止递归委派，硬规则的主语限定为主 Agent。

## 进度

- [x] 完成当前规则与角色配置核对。
- [x] 完成 planner 的独立方案审查。
- [x] 更新治理文档。
- [x] 完成静态验证与 reviewer 复核。
- [x] 归档计划并完成 history。

## 验证

- 相对链接和角色边界静态检查：通过。
- `git diff --check`：通过。
- 独立 reviewer 对最终差异的只读复核：未发现需要修复的 finding；复核快照与审查结束时一致。
- 不运行 `xcodebuild`，因为本次仅修改治理 Markdown。

## 完成条件

- reviewer 委派、等待、最终快照和不可用回退规则已落地。
- planner 与 reviewer 的职责和触发条件没有混淆。
- 静态检查与独立 reviewer 复核完成，计划归档并写入 history。

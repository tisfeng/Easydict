# 优化子代理配置与规则

- 状态：completed
- 创建日期：2026-09-07
- 负责人：tisfeng
- 关联 Issue/PR：none

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 目标结果：降低 planner 和 reviewer 的推理强度，并按职责收敛子代理委派与回退规则。
- 允许修改路径：`.codex/agents/`、`docs/agents/request-boundary.md`、
  `docs/agents/build-and-test.md`、`docs/references/astra-agent-guidance.md` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-07-optimize-subagent-rules.md`
- 禁止动作：不修改 tester 的模型、推理强度或沙箱，不修改产品代码或远程状态。
- 预期交付物：两个 effort 配置调整、按需委派规则、统一回退规则和精简的角色指令。
- 验收标准：TOML 配置矩阵准确，规则无重复冲突，静态检查和独立复核通过。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；初始索引和工作树为空，任务路径可独立识别。
- 初始 HEAD：`5e81a4ec6e87710f23dc3e3fda2118d80e28f681`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：`.codex/agents/planner.toml`、`.codex/agents/reviewer.toml`、
  `.codex/agents/tester.toml`、`docs/agents/request-boundary.md`、
  `docs/agents/build-and-test.md`、`docs/references/astra-agent-guidance.md` 以及本任务 plan/history。

## 目标与非目标

### 目标

- 将 planner 和 reviewer 的 `model_reasoning_effort` 改为 `medium`。
- 让 planner、reviewer 和 tester 的职责说明避免机械输出、直接转派或重复确认。
- 让 planner、reviewer 和 tester 按任务需要启用，并统一 custom agent 回退规则。

### 非目标

- 不调整任何子代理模型、tester 的 `high` 或沙箱能力。
- 不新增子代理框架，不修改通用 review Skill。

## 工作计划

1. 调整三个 custom agent 配置中的目标字段和局部职责文案。
2. 收敛 planning、review 和 test 的委派条件、回退流程及最终快照要求。
3. 同步 Astra 场景参考，验证 TOML、链接、规则场景和 Git diff。
4. 完成独立复核、归档计划并准备本地提交。

## 风险与决策

- `medium` 可能改变规划和审查深度；不承诺固定性能提升，以配置准确性和实际输出为准。
- planning 改为按需委派是明确的行为调整；只影响是否启动 planner，不改变 planning 的只读边界。
- 父 Agent 的编排规则保留在 `docs/agents/`，子代理自身边界保留在 TOML。

## 进度

- [x] 调整子代理配置。
- [x] 精简委派与回退规则。
- [x] 完成验证和独立复核。
- [x] 归档计划并完成本地提交准备。

## 验证

- Python `tomllib`：三个 custom agent 配置解析通过，模型、effort 和沙箱矩阵符合预期。
- 委派场景断言：简单 planning、复杂规划、reviewer/tester 按需选择和统一回退规则通过。
- 当前 Agent 规则及本任务记录的 Markdown 相对链接：通过。
- 排除范围：根 `AGENTS.md`、`.codex/config.toml` 和通用 review Skill 相对初始 HEAD 无变化。
- `git diff --check`：通过。
- 独立 reviewer：未发现有效 finding；配置、授权边界、角色职责和回退要求完整。
- Xcode 构建：未运行；本次仅修改子代理配置和治理文档。

## 完成条件

- planner/reviewer 为 `medium`，tester 保持 `high`。
- 简单 planning 不再机械启动 planner，reviewer/tester 可按实际需要独立启用。
- 所有角色回退遵循一个通用规则，角色自身安全边界保持完整。
- 静态检查和独立复核通过，计划已归档到 `completed/`。

# Planning 子代理编排

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Easydict 维护者
**Links:** OpenAI Subagents 文档、引用的 Codex 查证任务

## 任务契约

- 任务模式：`implementation`
- 用户目标：改进项目 Agent 规则，让非简单 `planning` 使用
  `gpt-5.6-sol`、`xhigh` 的只读子代理生成高质量规划建议。
- 允许动作：新增项目级 custom agent，修改 Agent 规则，执行针对性静态验证，
  记录计划与历史，并在符合仓库条件时自动本地提交。
- 允许修改路径：`.codex/agents/planner.toml`、
  `docs/agents/repository-guide.md`、`docs/agents/skills.md`、本执行计划和对应历史。
- 预期交付物：可被 Codex 发现的 `planner`、可执行的 planning 触发与回退规则、
  验证记录和本地提交。
- 验收标准：TOML 可解析且固定 Sol/xhigh/read-only；规则要求非简单 planning 启动并
  等待 `planner`，排除简单 planning，并禁止 planning 写入；文档检查通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`committed`

## 输入来源

- 用户明确请求：执行已确认的 planning 子代理方案。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、
  `docs/agents/skills.md` 和文档生命周期规则。
- 附件或引用材料：用户引用的 Codex 查证任务和 OpenAI Subagents 官方文档。
- 仅作为证据的内容：引用任务中的模型命名说明和已完成的只读方案评审。

## 目标

- 为项目新增一个只读 `planner` custom agent，并固定使用 `gpt-5.6-sol` 和 `xhigh`。
- 让每个任务都会读取的仓库指南定义非简单 planning 的稳定触发规则。
- 让 Agent 集成文档定义主 Agent 与子代理之间的编排、回退和授权边界。

## 范围

- 包含范围：项目级 custom agent、planning 规则、配置解析、计划和历史。
- 不包含范围：用户级 Codex 配置、全局子代理默认值、联网运行时 smoke test、产品源码、
  测试、Xcode 工程、implementation/review/test 专用子代理和并行写入工作流。

## 背景

- 原有行为：仓库已区分 `planning` 与 `implementation`，但没有 `.codex/agents/`
  项目配置或 subagent 编排规则。
- 相关文件：`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 约束：根 `AGENTS.md` 保持精简路由；子代理不能扩大用户授权或任务模式；
  `sandbox_mode` 不能代替文档中的只读规则。

## 风险与缓解

- 风险：对简单任务也启动高成本模型。
  - 缓解措施：只对定义明确的非简单 planning 强制触发，默认只启动一个 `planner`。
- 风险：模型、effort 或 custom agent 不可用时静默降级，造成错误的能力声明。
  - 缓解措施：禁止静默替换；按用户是否将精确配置设为硬性条件决定报告降级或阻塞。
- 风险：父会话实时权限覆盖 custom agent 的 sandbox 默认值。
  - 缓解措施：同时在仓库规则和 `developer_instructions` 中禁止 planning 写入。

## 里程碑

- [x] 确认范围、官方配置语义和初始 Git 状态。
- [x] 新增 `planner` 并更新 Agent 规则。
- [x] 完成 TOML、规则引用和 Git diff 静态检查。
- [x] 记录历史并将本计划移到 `completed/`。
- [x] 按仓库规则执行一次自动本地提交。

## 验证

- TOML 解析断言：通过；`planner` 固定为 `gpt-5.6-sol`、`xhigh` 和 `read-only`。
- 针对性 `rg`：通过；触发、回退、只读和禁止静默替换规则存在，未设置全局默认。
- `git diff --check`：通过。
- 静态复核：简单 planning 排除规则、主 Agent 最终责任和禁止递归委派边界完整。
- 未运行 `xcodebuild`，因为没有修改产品源码、测试或 Xcode 工程元数据。

## 决策记录

- 2026-08-23：使用项目级 `planner` 而不是 `[agents]` 全局默认，避免影响其他子代理。
- 2026-08-23：核心触发规则放入每个任务都会读取的 `repository-guide.md`，详细编排
  规则放入 `skills.md`；不修改根 `AGENTS.md` 或 `docs/agents/README.md`。
- 2026-08-23：固定精确模型 ID `gpt-5.6-sol`，并将 `xhigh` 作为独立 effort 配置。
- 2026-08-23：联网 smoke test 不是用户要求，也不是本次 Agent 文档和 TOML 配置的
  必要验收项；采用官方 schema 核对、配置解析和规则静态检查完成验证。

## 进度记录

- 2026-08-23：完成官方文档核对、只读方案评审和初始 Git 状态记录。
- 2026-08-23：完成 `planner`、Agent 规则、针对性验证和历史记录，计划归档。

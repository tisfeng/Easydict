# 2026-08-23 | 任务：新增 Planning 子代理编排

**Links:** `../../exec-plans/completed/2026-08-23-planning-subagent.md`

## 用户请求

改进项目 Agent 文档规则，让非简单 `planning` 使用 `gpt-5.6-sol`、`xhigh` 的
只读子代理形成规划建议，并由主 Agent 核验和交付最终方案。

## 变更

- 新增项目级 `.codex/agents/planner.toml`，固定模型、推理强度、只读行为和返回契约。
- 在仓库指南中定义非简单 planning 的触发、简单任务排除、等待和主 Agent 责任规则。
- 在 Agent 集成文档中定义 custom agent 调用、等价显式覆盖、回退、权限和禁止递归
  委派边界。

## 设计意图

使用职责聚焦的项目级 `planner`，将高强度规划能力限制在非简单 planning，而不改变
其他子代理的全局默认。配置和文档同时约束只读行为，避免父会话实时权限覆盖 sandbox
默认值时扩大写入范围；最终决策仍由掌握用户上下文的主 Agent 负责。

## 验证

- Python `tomllib` 解析断言：通过。
- 针对性 `rg`：触发、回退、只读和禁止静默替换规则存在；没有全局模型默认。
- `git diff --check`：通过。
- 未运行 `xcodebuild`，因为没有修改产品源码、测试或 Xcode 工程元数据。

## 受影响文件

- `.codex/agents/planner.toml`
- `docs/agents/repository-guide.md`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-08-23-planning-subagent.md`
- `docs/histories/2026-08/2026-08-23-planning-subagent.md`

## 后续事项

None

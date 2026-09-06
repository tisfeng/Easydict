# 2026-08-31 | 任务：说明 planner 需要较长等待

**Links:** [Codex Subagents 文档](https://learn.chatgpt.com/docs/agent-configuration/subagents)

### 用户请求

为使用高推理配置的 `planner` 明确增加较长响应时间提示，同时避免绑定某个具体的主模型名称。

### 变更

- 更新 `.codex/agents/planner.toml` 的 `description`，提醒调用方耐心等待，避免因短暂无输出提前终止或重复启动。
- 保留 `developer_instructions`、模型、推理强度和只读配置不变。

### 设计意图

`description` 用于 Codex 选择和启动 agent 时的角色提示，适合表达响应特征和调用注意事项；`developer_instructions` 用于定义 agent 自身行为，不负责控制父 Agent 的等待策略。描述不写入 `gpt-5.6-luna` 等具体模型名，避免主模型或 agent 模型调整后产生过时的比较。

### 验证

- 使用 Python `tomllib` 解析 `.codex/agents/planner.toml`。
- 使用 `git diff --check` 检查文本差异。
- 静态确认 `developer_instructions`、`model`、`model_reasoning_effort` 和 `sandbox_mode` 未改变。

### 受影响文件

- `.codex/agents/planner.toml`
- `docs/histories/2026-08-31-planner-latency-description.md`

### 后续事项

- 实际等待时长仍由父 Agent 的线程编排决定；本次只增加选择和启动时可见的提示。

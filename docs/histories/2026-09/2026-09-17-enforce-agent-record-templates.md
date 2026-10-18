## 2026-09-17 | 任务：统一 Agent 记录模板

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-17-enforce-agent-record-templates.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `gpt-5.6-sol`

### 用户请求

检查近期 plan 和 history 未遵循模板的问题，将 `Execution Context` 改为中文标题，并以简洁规则
约束后续记录。后续进一步明确模型信息优先来自对话上下文，无法取得完整模型 ID 时允许记录
base model，且不绑定特定客户端的数据格式。

### 变更

- 将 history 模板的 `Execution Context` 标题改为“执行上下文”。
- 在 Plan 与 History 规则中明确新建记录需要保留当前模板的必填字段、章节和顺序。
- 为模板变更后新增的近期 history 补齐执行上下文，并将 v2.9.2 更新记录整理为完整模板结构。
- 将 v0.6.0 Skill 升级计划的范围字段、章节顺序和验证结果整理为当前 plan 模板结构。
- 将 `Model ID` 改为兼容完整 ID 与 base model 的 `Model`，并修正相关记录中的模型值。

### 设计意图

模板只有在创建记录时被明确要求使用，才能成为稳定的写作入口。模型规则描述信息语义和优先级，
不依赖某个设备、客户端字段或本地存储路径，因此不同 Agent 应用也能采用同一模板。

### 验证

- `git diff --check`：通过。
- 章节检查：相关 history 和 completed plan 的必填字段、章节及顺序与当前模板一致。
- 相对链接检查：模板、历史记录、执行计划和关联本地文档目标均存在。
- 模型字段检查：相关 history 使用 `Model: gpt-5.6-sol`，模板保留 base model 与 `Unknown` 兜底。

### 受影响文件

- `docs/agents/README.md`
- `docs/histories/template.md`
- `docs/histories/2026-09/2026-09-16-record-history-execution-context.md`
- `docs/histories/2026-09/2026-09-17-app-path-management.md`
- `docs/histories/2026-09/2026-09-17-issue-translator-v2.9.2.md`
- `docs/histories/2026-09/2026-09-17-split-task-modes.md`
- `docs/histories/2026-09/2026-09-17-enforce-agent-record-templates.md`
- `docs/exec-plans/completed/2026-09/2026-09-15-upgrade-tisfeng-skills-v0.6.0.md`
- `docs/exec-plans/completed/2026-09/2026-09-17-enforce-agent-record-templates.md`

### 后续事项

- None

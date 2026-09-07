## 2026-09-07 | 任务：优化子代理配置与规则

**Links:** [执行计划](../../exec-plans/completed/2026-09-07-optimize-subagent-rules.md)

### 用户请求

将 planner 和 reviewer 的 `model_reasoning_effort` 改为 `medium`，并检查、优化和精简
所有子代理文档规则。

### 变更

- 将 planner 和 reviewer 的 `model_reasoning_effort` 从 `high` 调整为 `medium`；tester
  继续使用 `gpt-5.6-terra / high / workspace-write`。
- 精简 planner 输出契约、reviewer 测试建议交接和 tester 构建协调表述。
- 将 planner 改为复杂或重要规划按需委派，并统一 custom agent 的显式调用回退规则。
- 让 reviewer 和 tester 按行为风险及测试需要分别启用，最终结果覆盖实际采用的角色。
- 同步 Astra 场景参考，区分简单解释与跨模块规划。

### 设计意图

父 Agent 文档负责委派和回退，角色 TOML 负责子代理自身边界，使子代理按任务需要启用，
同时避免简单任务套用过重流程。

### 验证

- Python `tomllib`：三个 custom agent 配置解析及矩阵断言通过。
- 委派场景断言：通过。
- Markdown 相对链接及新锚点：通过。
- 根入口、Codex 基础配置和通用 review Skill：无变化。
- `git diff --check`：通过。
- 独立 reviewer：未发现有效 finding。
- 真实模型质量和运行时 custom-agent 加载：未验证，须由后续新启动角色实际观察。
- Xcode 构建：未运行；本次没有产品代码或测试代码变更。

### 受影响文件

- `.codex/agents/planner.toml`
- `.codex/agents/reviewer.toml`
- `.codex/agents/tester.toml`
- `docs/agents/request-boundary.md`
- `docs/agents/build-and-test.md`
- `docs/references/astra-agent-guidance.md`
- `docs/exec-plans/completed/2026-09-07-optimize-subagent-rules.md`
- `docs/histories/2026-09/2026-09-07-optimize-subagent-rules.md`

### 后续事项

- None

## 2026-09-06 | 任务：精简 Agent 文档文案

**Links:** [执行计划](../../exec-plans/completed/2026-09-06-agent-document-wording-cleanup.md)

### 用户请求

检查并改进项目中的 Agent 技能、根入口和 `docs/` 文档，删除奇怪、重复或容易误解的表述。

### 变更

- 精简根入口和 Agent 文档治理规则，删除重复路由、职责说明和模型配置副本。
- 修正本地 overlay 的冲突优先级表述，并简化 overlay 目录说明。
- 精简五个本地 Skill 的入口和局部重复文案，消除 YAML 解析后的异常中文空格。
- 精简 planner 描述，同时保留等待完成和禁止重复启动的行为要求。

### 设计意图

保留会改变执行行为的安全约束，使入口只负责路由、详细规则各自保持单一权威来源。

### 验证

- Ruby YAML 解析和等价 Skill 校验：8 个 Skill 通过。
- Python `tomllib`：3 个 custom agent 配置通过。
- 相对链接检查：50 个当前规则文件通过，0 个失效链接。
- `git diff --check`：通过。
- 独立 reviewer：未发现有效 finding。
- `quick_validate.py`：当前 Python 缺少 `PyYAML`；已读取脚本并用 Ruby 执行等价检查。

### 受影响文件

- `AGENTS.md`
- `docs/agents/README.md`
- `docs/agents/build-and-test.md`
- `docs/agents/execution-safety.md`
- `docs/agents/response-conventions.md`
- `.agents/overrides/README.md`
- `.agents/overrides/fireworks-tech-graph/layout.md`
- `.agents/skills/code-simplifier/SKILL.md`
- `.agents/skills/git-commit/SKILL.md`
- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/review-pr/SKILL.md`
- `.agents/skills/worktree-rebase-merge/SKILL.md`
- `.codex/agents/planner.toml`
- `docs/exec-plans/completed/2026-09-06-agent-document-wording-cleanup.md`
- `docs/histories/2026-09/2026-09-06-agent-document-wording-cleanup.md`

### 后续事项

- None

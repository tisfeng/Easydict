## 2026-09-06 | 任务：移除 Skill 覆盖层

**Links:** [执行计划](../../exec-plans/completed/2026-09-06-remove-skill-overrides.md)

### 用户请求

删除 `.agents/overrides/`，不再覆盖项目级 Skill，并同步清理相关规则。

### 变更

- 删除 `.agents/overrides/README.md` 和
  `.agents/overrides/fireworks-tech-graph/layout.md`，并移除空目录。
- 将根入口的具体 Skill 路由收敛为 `.agents/skills/<skill>/SKILL.md`。
- 清理 Agent 文档治理和请求边界中的 overlay 存放、加载和优先级表述。

### 设计意图

项目继续使用标准的 `.agents/skills/` 布局，每个 Skill 以自身 `SKILL.md` 为行为来源，
不再加载仓库级覆盖层。

### 验证

- 覆盖目录缺失检查：通过。
- 当前规则引用扫描：未发现残留的 overlay 加载规则。
- `.agents/skills/` 相对初始 HEAD：无变化。
- Markdown 相对链接检查：39 个链接通过。
- `.claude` 兼容符号链接：有效。
- `git diff --check`：通过。
- 独立 reviewer：未发现有效 finding。
- Xcode 构建：未运行；本次没有产品代码变更。

### 受影响文件

- `.agents/overrides/README.md`（删除）
- `.agents/overrides/fireworks-tech-graph/layout.md`（删除）
- `AGENTS.md`
- `docs/agents/README.md`
- `docs/agents/request-boundary.md`
- `docs/exec-plans/completed/2026-09-06-remove-skill-overrides.md`
- `docs/histories/2026-09/2026-09-06-remove-skill-overrides.md`

### 后续事项

- None

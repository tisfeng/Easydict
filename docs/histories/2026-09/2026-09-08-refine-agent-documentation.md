## 2026-09-08 | 任务：优化 Agent 文档表达与规则边界

**Links:** [执行计划](../../exec-plans/completed/2026-09-08-refine-agent-documentation.md)

### 用户请求

重新检查现行 Agent 文档，精简重复描述并消除冲突；保留 `Plan` 与 `History` 术语，将难以
理解的 Git 路径范围规则改写为自然、可执行的表达。

### 变更

- 明确 `AGENTS.md` 同时维护通用约束和唯一任务路由，删除其中已由专题文档维护的重复条款。
- 将交付授权定义为操作类别，区分创建 PR 与 PR review，并明确带 push 的 PR 或发布工作流
  可以提供对应授权。
- 区分 implementation 的写入前快照与只读交付基线，将提交路径规则改写为“逐一列入、不能
  遗漏、不能混入用户或范围外改动”。
- 明确治理文档的静态检查默认值不覆盖用户明确要求的 Xcode 验证，并准确限定 tester 禁止的
  Git 操作。
- 合并重复的 history、Xcode 并发和委派输入描述，修正不自然表述及 lock 能力的过度承诺。
- 保留 `Plan 与 History` 标题和现行根入口加五份专题规则的结构。

### 设计意图

在不改变现有授权、安全、验证和交付行为的前提下，使每项规则只有一个清晰的权威来源。

### 验证

- `git diff --check`：通过。
- 本任务 10 个 Markdown 的 18 个相对文件链接：全部可解析；引用锚点存在。
- 9 个代表性授权、交付、验证和受管资产场景：检查通过。
- 目标旧表达和已删除 Agent 文档的活动引用：没有残留。
- 独立 reviewer：没有发现尚未解决的阻塞问题；最终措辞调整已增量复审。
- 未运行 Xcode，因为本次只有治理 Markdown；未验证真实 Git、Codex 运行时或远程行为。

### 受影响文件

- `AGENTS.md`
- `docs/agents/README.md`
- `docs/agents/build-and-test.md`
- `docs/agents/development.md`
- `docs/agents/git-workflow.md`
- `docs/agents/request-boundary.md`
- `docs/design-docs/agent-documentation-structure.md`
- `docs/design-docs/external-agent-assets-management.md`
- `docs/exec-plans/completed/2026-09-08-refine-agent-documentation.md`

### 后续事项

- 无。

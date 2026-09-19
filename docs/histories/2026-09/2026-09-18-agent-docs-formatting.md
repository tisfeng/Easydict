## 2026-09-18 | 任务：统一 Agent 文档排版

**Links:** None

### 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-individual-coding-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

整体检查 agent 文档并给出格式优化方案；其中执行前步骤对 plan/history README 的链接与任务
路由重复，要求去掉链接形式。

### 变更

- `AGENTS.md` 执行前步骤改为纯文本路径，链接只保留在任务路由一处。
- `AGENTS.md` 两条超宽路由行（121/113 列）按续行风格换行，通用规则第三条和执行模式 Review
  步骤的失衡换行重新平衡，全部正文不超过 100 显示列。
- 两个模板的「执行上下文」HTML 注释逐行重排到 100 列内，文字不变。

### 设计意图

链接按「显示处单一来源」原则只在任务路由出现；正文换行遵循全库 ≤100 显示列（CJK 计 2）
约定，断行落在子句边界。模板占位符行是完整的 inline-code 值，不可拆行，保留为唯一超宽
例外。

### 验证

- 行宽复查（10 个 agent 文档）：注释与正文全部 ≤100 列，仅两处模板 Environment 占位符行
  （105 列）作为不可拆行例外保留。
- 全库链接与锚点校验（115 个链接）：零失败。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown 排版。

### 受影响文件

- `AGENTS.md`
- `docs/exec-plans/templates.md`
- `docs/histories/2026-09/2026-09-18-agent-docs-formatting.md`
- `docs/histories/template.md`

### 后续事项

- None

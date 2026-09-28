## 2026-09-13 | 任务：整理 Agent 文档排版

**Links:** None

### 用户请求

检查并执行 `AGENTS.md` 及现行 Agent 专题文档中的格式排版改进。

### 变更

- 保留并纳入用户对 `AGENTS.md` 开头段落的换行整理，合并两条任务路由中的短尾续行。
- 合并编码规范中 3 处可在合理行宽内完整展示的规则，并移除重复的 Swift 标题层级。

### 设计意图

只处理已确认的源码排版问题，不机械重排全部 Markdown，也不引入新的强制行宽规则或改变规则语义。

### 验证

- Markdown 标题、空白、Tab、尾随空格和代码围栏检查：通过。
- 相对链接与锚点检查：通过。
- `git diff --check`：通过。

### 受影响文件

- `AGENTS.md`
- `docs/agents/coding-guidelines.md`
- `docs/histories/2026-09/2026-09-13-normalize-agent-doc-formatting.md`

### 后续事项

- None

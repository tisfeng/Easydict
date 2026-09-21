## 2026-09-13 | 任务：进一步精简 Agent 文档

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-13-streamline-agent-docs.md)

### 用户请求

继续检查并精简 Agent 文档，删除已确认多余的 Issue 自动关闭规则，并按批注完整保留构建测试
命令、编码规范主体、执行计划主要结构、history 模板和贡献指南。同时将放错目录的 OCR history
移入对应月份目录。

### 变更

- 精简根入口、任务模式和 Agent 治理文档，移除通用工具能力、模糊路由和重复模式说明。
- 压缩构建测试规则的解释但完整保留命令；编码规范只取消类型文档的固定字符数要求；执行计划
  模板只移除 Git 初始状态字段。
- 删除重复的 Agent 文档结构设计和移植 reference，压缩资产治理设计与 Astra 来源记录并更新索引。
- 将 `docs/histories/2026-09-11-ocr-debug-window-dragging.md` 移至 `docs/histories/2026-09/`。

### 设计意图

仓库规则只保留 Easydict 特有且无法从系统、Skill、源码或工具配置直接推断的约束。历史来源和
非显然的外部资产治理仍保留，同时避免改动用户明确要求维持的内容。

### 验证

- 已删除内容与旧路径的现行引用检索：无残留。
- Markdown 相对链接与锚点检查：通过。
- `git diff --check`：通过。
- 内容等价检查：编译测试命令、OCR history 正文、`CONTRIBUTING.md` 和 history 模板均未改变。
- 差异检查：`coding-guidelines.md` 只有类型文档规则发生变化。
- `xcodebuild`：未运行；本任务只修改不进入 Xcode 构建图的治理 Markdown。

### 受影响文件

- `AGENTS.md`
- `docs/agents/`
- `docs/design-docs/`
- `docs/exec-plans/templates.md`
- `docs/exec-plans/completed/2026-09/2026-09-13-streamline-agent-docs.md`
- `docs/histories/2026-09/2026-09-11-ocr-debug-window-dragging.md`
- `docs/histories/2026-09/2026-09-13-streamline-agent-docs.md`
- `docs/references/`

### 后续事项

- None

## 2026-08-09 | 任务：迁移 Agent 文档结构

**Links:** `AGENTS.md`, `docs/exec-plans/completed/2026-08-09-agent-structure-migration.md`

### 用户请求

按职责分离 Easydict 的 Agent 规则和文档，并将现有英文和中文公共文档放入专用目录。

### 变更

- 将 `docs/en` 和 `docs/zh` 移到 `docs/user-docs/en` 和 `docs/user-docs/zh`。
- 将文本选择流程图移到 `docs/architecture/`。
- 将长期 Swift 迁移路线图从仓库根目录移到 `docs/exec-plans/active/`，并修复其
  生命周期链接。
- 将原本很长的根目录 `AGENTS.md` 替换为路由入口，并将规则拆分到 `docs/agents/`。
- 添加架构、计划、历史记录、设计文档和参考资料索引。
- 添加生成器和结构化文档检查器。

### 设计意图

Agent 指令、实现事实、任务记录和公共文档面向不同读者，更新生命周期也不同。将它们
分开可以保持根目录 Agent 提示简洁，同时保留可发现的公共链接，并为仓库规则保留唯一
事实来源。

### 验证

- `git diff --check`：通过。
- `bash -n scripts/*.sh`：通过。
- `scripts/check-agent-docs.sh`：通过。
- 本地 README 和公共文档链接：迁移后已检查。

### 受影响文件

- `AGENTS.md`
- `docs/agents/`
- `docs/architecture/`
- `docs/user-docs/`
- `docs/exec-plans/`
- `docs/histories/`
- `README.md`
- `README_ZH.md`
- `scripts/`

### 后续事项

- 保持后续架构和任务历史文档与对应的生命周期索引一致。

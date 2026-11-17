## 2026-09-20 | 任务：移除发布 Skill 的开发者指南引用

**Links:** none

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

移除 Release 生命周期执行契约对长篇开发者指南的反向引用，避免 Agent 在发布任务中加载
不必要的用户文档。

### 变更

- 删除 `release-workflow.md` 对 `docs/releases/easydict.md` 的链接。
- 将开头说明收敛为 Agent 的动作选择、内容决策、外部写入和恢复契约。

### 设计意图

保持开发者文档到 Skill 的单向说明关系。Release 生命周期只加载会改变 Agent 执行决策的
约束，Apple 账号配置、完整命令和实现说明继续由开发者指南独立承载。

### 验证

- `quick_validate.py .agents/skills/release-easydict`：临时 Python 3.12 环境中通过。
- `release-workflow.md` 的 2 个相对 Markdown 链接：目标均存在。
- 发布 Skill 内 `docs/releases/easydict.md` 引用扫描：无结果。
- `git diff --check`：通过。
- 未运行发布单元测试或真实发布流程；本次只修改一段 Skill 文档路由。

### 受影响文件

- `.agents/skills/release-easydict/references/release-workflow.md`
- `docs/histories/2026-09/2026-09-20-remove-release-guide-skill-link.md`

### 后续事项

None

## 2026-09-20 | 任务：合并 Easydict 发布开发者文档

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-20-merge-release-developer-guide.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将发布引擎说明与 `docs/releases/easydict.md` 合并成一份面向开发者的发布指南，不再维护
两份相似文档。

### 变更

- 将 Git/worktree 模型、beta 轮换、构建缓存、14 个 workflow 检查点、状态日志、文件职责
  和 fail-closed 条件合并进 `docs/releases/easydict.md`，并保留 Apple 账号、签名凭据和命令说明。
- 删除重复的 `release-engine.md`，使开发者指南成为发布配置、操作、恢复和维护的唯一入口。
- 更新 `release-easydict` Skill，只加载 Release 生命周期执行契约；把契约内重复的 helper
  命令教程收敛为 Agent 动作选择规则。

### 设计意图

开发者知识统一放在 `docs/releases/easydict.md`，Agent 专属 reference 只保留授权、决策、
外部写入和恢复约束。这样既避免两份教程随实现变化而漂移，也不削弱发布 Skill 的安全边界。

### 验证

- 临时 Python 3.12 环境安装 `PyYAML` 和固定的 `Markdown==3.8.1` 后运行
  `quick_validate.py .agents/skills/release-easydict`：通过；系统 Python 因缺少这两个验证
  依赖未直接使用。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：
  临时 Python 3.12 环境中 71 个测试全部通过。
- `bash -n .agents/skills/release-easydict/scripts/*.sh` 与
  `plutil -lint .agents/skills/release-easydict/assets/export-options.plist`：通过。
- 4 个相关 Markdown 文件的 7 个相对链接、现行 `release-engine.md` 引用扫描和
  `git diff --check`：通过。
- 未运行 Archive、公证或远程发布流程；本任务只验证文档和 Skill 结构、静态规则及单元测试。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-engine.md`（删除）
- `.agents/skills/release-easydict/references/release-workflow.md`
- `docs/releases/easydict.md`
- `docs/exec-plans/completed/2026-09/2026-09-20-merge-release-developer-guide.md`
- `docs/histories/2026-09/2026-09-20-merge-release-developer-guide.md`

### 后续事项

None

## 2026-11-27 | 任务：升级受管 Skills 至 v0.10.0

**Links:** [Skills v0.10.0](https://github.com/tisfeng/skills/releases/tag/v0.10.0)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

发布 Skills 新版本后更新本项目的 `tisfeng/skills` 依赖。

### 变更

- 按固定 tag 的安装结果同步六项受管技能及 lock，将 `code-simplifier` 迁移到 `code-maintenance` 并保留其完整平台指南。
- 更新现行安装说明和版本依据。

### 设计意图

以固定发布版本及隔离安装生成的锁定条目为准，保留本项目的独立来源和本地技能。

### 验证

- 用 `skills@1.5.25` 固定 tag 安装结果核对六个目录的文件清单、内容及独立重算的 SHA-256。
- `git diff --check`、新文件空白检查、lock JSON 和安装入口检查通过。

### 受影响文件

- `.agents/skills/` 下的受管技能
- `skills-lock.json`
- `docs/agents/skills.md`

### 后续事项

- None

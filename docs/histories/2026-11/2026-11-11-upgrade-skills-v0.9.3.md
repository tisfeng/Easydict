## 2026-11-11 | 任务：同步受管 Skills 至 v0.9.3

**Links:** [Skills v0.9.3](https://github.com/tisfeng/skills/releases/tag/v0.9.3)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode Unknown (Unknown)`

### 用户请求

发布共享 Skills 新版本后升级本项目的受管技能。

### 变更

- 六个 `tisfeng/skills` 快照从 `v0.9.2` 同步至 `v0.9.3`，并更新 lock 和来源基线。

### 设计意图

使用固定 tag 保持技能可离线审查，并保留项目专属规则。

### 验证

- 六个安装目录的 56 个文件逐一匹配上游固定 tag，重算的六项 SHA-256 与 lock 一致。已核对 frontmatter、相对链接、Python 和 Shell 语法，第三方 lock 条目与项目自有 Skill 未变化。

### 受影响文件

- `.agents/skills/` 下六个受管目录、`skills-lock.json` 和 `docs/agents/skills.md`。

### 后续事项

- 本次以本地提交交付。

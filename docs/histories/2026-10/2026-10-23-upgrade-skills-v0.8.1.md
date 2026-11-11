## 2026-10-23 | 任务：更新受管 Skills 到 v0.8.1

**Links:** [Release v0.8.1](https://github.com/tisfeng/skills/releases/tag/v0.8.1)、[执行计划](../../exec-plans/completed/2026-10/2026-10-23-upgrade-skills-v0.8.1.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

发布 skills 新版本后，通过正常安装流程更新 Easydict 的受管副本；不创建或切换分支。

### 变更

- 使用规定的 skills@1.5.25 安装器，将六个 tisfeng/skills 受管 Skill 固定升级到 v0.8.1。
- submit-pr 的标题统一使用英文，正文和报告继续按用户语言偏好生成；安装器更新 lock ref 和目录 hash。
- 更新来源基线、安装命令及 tag 身份；保留其他来源和项目专属资产。

### 设计意图

从不可变的已发布 tag 同步完整快照，通过文件比较与目录级 hash 证明来源，避免手工修改受管副本。

### 验证

- 来源 tag object：d033324dd8e3b882ad8694836693df5dfd5e12a6；peeled commit：1b40de2c4a1b03dcc117b14a1d089d3445bb2b9c；本地与远程一致。
- 来源 Release workflow 成功，Release 标题精确为 v0.8.1，正文与 tag 内 changelog 全文一致。
- 固定 tag 隔离安装及本仓库安装均成功；56 个文件、六个 lock 条目及重算目录 hash 匹配。
- submit-pr 现有 30 项测试通过，禁用字节码输出；源码仓库完整矩阵 137 项及发布 SHA CI 已通过。
- git diff --check、lock JSON、相对链接与受影响文档检查通过；本次不涉及产品工程，不运行 Xcode 构建。
- 手动核对：fireworks-tech-graph、release-easydict、第三方 lock 条目及 .claude/skills 链接与初始快照一致。

### 受影响文件

- `.agents/skills/submit-pr/SKILL.md`
- `.agents/skills/submit-pr/references/workflow.md`
- `skills-lock.json`
- `docs/agents/skills.md`
- 本任务归档计划与 history。

### 后续事项

- 本次只创建 dev 上的本地提交，不 push 或创建 PR。

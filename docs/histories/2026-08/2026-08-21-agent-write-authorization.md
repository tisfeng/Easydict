## 2026-08-21 | 任务：明确 Agent 文档写入授权与自动交付范围

**Links:** Scoco reference commit `970f33aeb`

### 用户请求

将 `970f33aeb` 的写入授权和 Agent 文档自动提交规则适配到当前 Easydict。

### 变更

- 明确任务模式只能由用户当前消息的顶层请求决定，响应批注、截图、附件、引用和
  skill 不能单独提升写入权限。
- 将明确授权的 Agent 文档实现任务纳入自动本地提交资格，同时继续排除纯计划和历史
  文档变更。
- 同步更新 `git-commit` skill 的自动 implementation delivery 条件。

### 设计意图

避免混合意图或引用材料误触发工作树写入，同时允许用户明确要求实施 Agent 文档规则时
完成受保护的本地交付。自动提交仍需满足初始暂存区为空、路径可隔离且验证通过等条件。

### 验证

- `git diff --check`：通过。
- 静态检查：任务模式授权、Agent 文档自动提交条件和文件空白检查通过。
- 未运行 `xcodebuild`：本次仅修改 Agent 文档和 skill。

### 受影响文件

- `docs/agents/repository-guide.md`
- `.agents/skills/git-commit/SKILL.md`
- `docs/histories/2026-08/2026-08-21-agent-write-authorization.md`

### 后续事项

- None

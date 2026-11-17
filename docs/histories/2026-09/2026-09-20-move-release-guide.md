## 2026-09-20 | 任务：将发布指南移出 Agent 文档目录

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [Easydict 发布指南](../../releases/easydict.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将面向发布维护者的 Easydict 发布指南移出 `docs/agents/`，放入更合适的公开文档目录。

### 变更

- 将发布指南迁移为 `docs/releases/easydict.md`，并改成面向发布维护者的说明。
- 移除 Agent Skill 管理文档中对发布指南的路由链接。
- 更新 `scripts/release/README.md` 的总览入口。
- 删除指南中的 Agent 路由语气，保留 Apple 凭据、发布命令、Issue 跟进和恢复说明。

### 设计意图

`docs/agents/` 只保留 Agent 执行规则，`docs/releases/` 承载维护者使用的发布手册；
`release-easydict` Skill 继续作为 Agent 的实际执行入口，不在 Agent 文档中重复路由说明。

### 验证

- 4 个变更文档的相对 Markdown 链接检查：通过。
- 现行文档中的旧路径和 Agent 路由措辞扫描：无残留。
- `git diff --check`：通过。
- 未执行真实构建、公证或远程发布。

### 受影响文件

- `docs/releases/easydict.md`
- `docs/agents/skills.md`
- `scripts/release/README.md`
- `docs/agents/release-easydict.md`（删除）
- `docs/histories/2026-09/2026-09-20-move-release-guide.md`

### 后续事项

- None

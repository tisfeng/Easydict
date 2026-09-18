## 2026-09-18 | 任务：AGENTS.md 文件引用改为链接

**Links:** None

### 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-individual-coding-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将根目录 `AGENTS.md` 中的文件引用统一改为可点击的 Markdown 链接，显示文字只保留文件名或目录名，方便跳转查看。

### 变更

- 将执行模式和任务路由中的 7 处文件引用改为从仓库根目录出发的 Markdown 链接。
- 执行前读取的 `docs/agents/README.md` 引用附加 `#plan-与-history` 锚点直达章节。
- `review` 技能引用链接到 `.agents/skills/review/SKILL.md`。
- 公共文档目录只在任务路由链接一次：使用 `en/zh` 显示文字链接到 `docs/user-docs/`；
  通用规则中的公共文档目录描述已删除，不再重复。
- 第 5 行 `AGENTS.md` 自引用保持原样，不改。

### 设计意图

链接目标使用相对仓库路径，显示文字只保留文件名或目录名，与 `docs/agents/README.md` 已有的
[`AGENTS.md`](../../AGENTS.md) 引用风格一致；显示文字与链接目标分离，正文保持简洁且可跳转。

### 验证

- Python 脚本校验 `AGENTS.md` 全部 7 个 Markdown 链接：目标文件或目录存在，锚点与目标文档标题的
  GitHub slug 一致，全部通过。
- 手动检查：剩余反引号引用仅第 5 行 `AGENTS.md` 自引用，符合用户要求。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

### 受影响文件

- `AGENTS.md`
- `docs/histories/2026-09/2026-09-18-agents-md-links.md`

### 后续事项

- None

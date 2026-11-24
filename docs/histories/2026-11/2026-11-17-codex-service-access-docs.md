## 2026-11-17 | 任务：说明 Codex 服务的两种接入方式

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode Unknown (Unknown)`

### 用户请求

将官网服务总览中的 Codex CLI 更名为 Codex，说明两种接入方式，同步更新 GitHub README。

### 变更

- 在中英文 README 和服务总览中说明本机 Codex CLI 和 ChatGPT 登录（内置）两种方式。
- 补充英文使用指南的 Codex 翻译章节，并在两种语言的 README 和服务总览中链接对应说明。

### 设计意图

对齐设置页的显示名称，保留 `CodexCLI` 服务标识；官网从应用仓库的固定提交同步文档，避免维护两份内容。

### 验证

- `git diff --check`：通过。
- 手动检查：两种接入方式与 App 本地化文案及中文指南一致，英文和中文链接各指向对应章节。
- 未运行 Xcode 构建：仅修改文档。

### 受影响文件

- `README.md`、`README_ZH.md`
- `docs/user-docs/en/GUIDE.md`
- `docs/user-docs/en/SERVICES.md`、`docs/user-docs/zh/SERVICES.md`

### 后续事项

- None

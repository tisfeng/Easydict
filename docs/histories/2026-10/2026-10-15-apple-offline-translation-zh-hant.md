## 2026-10-15 | 任务：修正 Apple 离线翻译说明的繁体用词

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** https://github.com/tisfeng/Easydict/pull/1340, https://github.com/tisfeng/Easydict/issues/1338

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

审查 PR #1340 后，修复 F1：Apple 离线翻译说明的 `zh-Hant` 文案使用了大陆用词。

### 变更

- `service.configuration.apple.offline_translation.description` 的 `zh-Hant` 值中，
  “設備”改为“裝置”，“系統設置”改为“系統設定”，链接与其余文本不变。

### 设计意图

与 Apple 繁体中文系统界面及仓库现有繁体文案的主流用词保持一致，只改单个 locale 的值，
不调整 key 或其他语言。

### 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `git diff --check`：通过。
- 手动检查：diff 仅包含该 `zh-Hant` 值的用词替换。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`

### 后续事项

- None

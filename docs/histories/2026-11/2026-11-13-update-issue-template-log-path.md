## 2026-11-13 | 任务：同步 Issue 模板日志路径

**Links:** [应用路径管理](../../design-docs/app-path-management.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

检查 GitHub Issue 模板，更新日志迁移后仍引用旧目录的说明。

### 变更

- 将中英文 Bug Report 模板中的日志目录更新为 `~/Library/Application Support/com.izual.Easydict/logs/app`。

### 设计意图

使用与「帮助 → 日志目录」一致的正式版应用日志根目录，并保留通过「导出日志」提交 ZIP 的操作说明。

### 验证

- 使用 Ruby YAML 解析两个模板并与原版比较，确认只有日志目录示例更新。
- 核对本机目录存在，并与 `AppPathManager.appLogDirectory` 和菜单入口一致。
- `git diff --check` 通过。

### 受影响文件

- `.github/ISSUE_TEMPLATE/cn_bug_report_zh.yml`
- `.github/ISSUE_TEMPLATE/en_bug_report.yml`

### 后续事项

- None

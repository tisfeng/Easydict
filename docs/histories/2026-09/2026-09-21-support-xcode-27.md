## 2026-09-21 | 任务：支持 Xcode 27 的 CodeQL 构建

**Links:** [PR #1274](https://github.com/tisfeng/Easydict/pull/1274)、
[执行计划](../../exec-plans/completed/2026-09/2026-09-21-support-xcode-27.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-5
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

将 Swift CodeQL 构建迁移到 GitHub Actions 的 `xcode-27` runner，以支持 PR #1274 使用的 macOS 27 Icon Composer 图标格式。

### 变更

- `.github/workflows/codeql.yml` 的 Swift CodeQL job 从 `macos-latest` 改为 `xcode-27`。
- 构建环境步骤增加 `sw_vers -productVersion`，并拒绝非 Xcode 27 或非 macOS 27 的 runner。
- 保留现有 arm64 构建、SwiftPM 缓存、CodeQL 版本和其他 workflow，不修改应用资源或源码。

### 设计意图

`macos-latest` 当前使用 macOS 26/Xcode 26，`actool` 无法解析 `Easydict-27.icon`；`xcode-27` 提供 macOS 27/Xcode 27。版本门禁避免 runner label 将来漂移时静默退回不兼容工具链。缓存 key 已包含 Xcode 版本，因此 Xcode 26 与 Xcode 27 的 SwiftPM 缓存自动隔离。

### 验证

- YAML 解析：通过。
- 提取 workflow 中的 Shell 脚本并运行 `bash -n`：通过。
- workflow 关键断言和 `git diff --check`：通过。
- review：未发现 finding。
- 未运行 GitHub Actions 在线 CI；本地未 push。

### 受影响文件

- `.github/workflows/codeql.yml`
- `docs/exec-plans/completed/2026-09/2026-09-21-support-xcode-27.md`
- `docs/histories/2026-09/2026-09-21-support-xcode-27.md`

### 后续事项

- Push 后观察 `Analyze (swift)` 是否在日志中报告 macOS 27/Xcode 27，并确认 `actool` 能成功编译 `Easydict-27.icon`。
- `xcode-27` 仍是 GitHub Actions Public Preview；如出现排队或容量问题，再评估 `xcode-27-xlarge`。

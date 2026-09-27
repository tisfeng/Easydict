## 2026-09-24 | 任务：缩小 SwiftLint 扫描范围

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-24-swiftlint-scope.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

检查 Xcode 构建阶段的 SwiftLint 耗时，解释 `.swiftlint.yml` 已排除 `.tmp` 却仍很慢的原因，
并修复扫描范围；`.tmp` 清理留待以后。

### 变更

- 在 `.swiftlint.yml` 用 `included` 限制扫描到 `Easydict`、`EasydictTests` 和 `BuildTools` 的两个 Swift 文件。
- 移除顶层路径 `excluded` 列表；`identifier_name.excluded` 仍保留，用于规则中的标识符例外。

### 设计意图

旧配置从仓库根目录执行时超过 45 秒仍未完成。相同的 SwiftLint 0.62.2 加入 `included`
但保留顶层 `excluded` 时仍超过 60 秒；隔离试验中，单独加入 `.tmp` 等顶层排除项均超过
8 秒，不加顶层排除项则约 1.3 秒。说明旧的路径排除配置在本地目录规模下带来显著开销；
通过明确扫描入口，使 `.tmp` 和 `BuildTools/.build` 不再处于候选目录内。

### 验证

- `swiftlint lint --no-cache`：最终配置 1.21 秒完成，408 文件、0 违规；与当前跟踪的 Swift 文件数一致。
- `git diff --check`：通过。
- 未运行完整 Xcode 构建；使用 Xcode DerivedData 中构建阶段所用的 SwiftLint 0.62.2 可执行文件验证。

### 受影响文件

- `.swiftlint.yml`
- `docs/exec-plans/completed/2026-09/2026-09-24-swiftlint-scope.md`
- `docs/histories/2026-09/2026-09-24-swiftlint-scope.md`

### 后续事项

- `.tmp` 容量清理另行处理；如新增顶层 Swift 源码目录或 `BuildTools` 文件，需更新 `included`。

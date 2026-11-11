## 2026-11-11 | 任务：禁止手动设置 ENABLE_PREVIEWS

**Links:** [构建与测试规范](../../agents/build-and-test.md#选择验证)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

在仓库规则中禁止 Agent 手动添加 ENABLE_PREVIEWS 参数。

### 变更

- 在构建与测试规范中禁止通过命令行或环境变量手动设置该值。

### 设计意图

由 Xcode 管理预览设置，让常规构建和测试按项目配置运行 SwiftFormat。

### 验证

- 检查规则与 Xcode Format 构建阶段的行为一致。
- `git diff --check` 通过。

### 受影响文件

- `docs/agents/build-and-test.md`

### 后续事项

- None

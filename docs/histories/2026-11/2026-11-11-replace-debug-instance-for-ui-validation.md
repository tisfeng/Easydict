## 2026-11-11 | 任务：自动替换界面验收前的旧调试实例

**Links:** [应用实例与界面验证](../../agents/build-and-test.md#应用实例与界面验证)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

即使 Xcode 正在调试 Easydict，也允许 Agent 自动退出旧应用并启动本次待验收构建。

### 变更

- 先完成构建，再确认旧 Debug 实例、停止运行并核对退出，随后按产物路径启动验证应用。
- 将自动替换限定在界面验收所需的 Easydict Debug 实例。

### 设计意图

让界面验收连续执行，同时避免影响正式版、Xcode 本身和无关进程。

### 验证

- `git diff --check`：通过。
- 手动检查：核对规则、相对链接及锚点。

### 受影响文件

- `docs/agents/build-and-test.md`

### 后续事项

- None

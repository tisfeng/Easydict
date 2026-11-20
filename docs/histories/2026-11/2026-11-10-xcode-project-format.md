## 2026-11-10 | 任务：保留 Xcode 工程格式整理

**Links:** 基线 `49d970a18`

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

恢复工程级 Debug 的 `DEVELOPMENT_TEAM` 变量引用，保留 Xcode 的格式调整，并独立提交。

### 变更

- 恢复工程级 Debug 的 `DEVELOPMENT_TEAM = "$(DEVELOPMENT_TEAM)"`。保留工程对象排序和桥接头路径的引号调整。

### 设计意图

Debug 签名继续由本地配置决定。提交后的工程配置与基线语义一致。

### 验证

- `plutil -lint` 和 `git diff --check` 通过。
- 解析前后工程文件并比较全部对象、属性和数组，结果相等。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- None

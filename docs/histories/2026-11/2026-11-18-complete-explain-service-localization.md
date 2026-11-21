## 2026-11-18 | 任务：补齐讲解服务的译名

**Links:** [PR #1407 审查评论](https://github.com/tisfeng/Easydict/pull/1407#discussion_r4603137085)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2.1 / Xcode 27.2 (27B52)

### 用户请求

补齐「这是什么」的三种服务译名，验证后推送到 PR #1407，并处理审查线程。

### 变更

- 为 `explain_service` 补齐西班牙语 `Explicación`、日语 `解説` 和乌尔都语 `وضاحت`。

### 设计意图

采用与同组服务一致的简短功能名称，覆盖应用目前的全部七种界面语言。

### 验证

- `xcodebuild build`（Debug）：通过。
- `git diff --check` 与 `jq -e .`：通过。解包检查确认三种编译后资源均包含相应译名。
- 手动检查：从新构建的空白查询窗口分别验证三个语言版本的服务标签，并在仓库外保存截图。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`

### 后续事项

- None

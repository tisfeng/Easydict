## 2026-11-08 | 任务：修复表格中未配对反引号的分列

**Links:** [PR #1375 审查评论](https://github.com/tisfeng/Easydict/pull/1375#discussion_r4506090571)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

解决 PR 新评论指出的表格分列问题并验证。

### 变更

- 表格单元格扫描仅在找到等长的闭合反引号时跳过代码跨度。

### 设计意图

未配对的反引号按字面文本处理，后面的竖线仍可分列。成对的代码跨度和转义竖线保留在原单元格内。

### 验证

- `xcodebuild test -only-testing:EasydictTests/MarkdownRendererTests`：27 项通过。
- 临时解析检查：复现旧版失败，修复后表头、数据行、成对代码跨度、转义竖线及表后正文均符合预期。
- 实机检查：固定流式响应经实际结果卡片显示，核对两列内容并截图。
- `git diff --check` 通过，代码审查未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/MarkdownBlockParser.swift`

### 后续事项

- None

## 2026-11-08 | 任务：修复表格代码跨度末尾的反斜杠

**Links:** [PR #1375 审查评论](https://github.com/tisfeng/Easydict/pull/1375#discussion_r4506439352) · [CommonMark 代码跨度](https://spec.commonmark.org/0.31.2/#code-spans)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

修复并验证表格代码跨度以反斜杠结尾时分列失败的问题。

### 变更

- 搜索闭合反引号时按字面处理代码跨度内的反斜杠。

### 设计意图

遵循 CommonMark 的代码跨度规则，保留跨度外已有的转义处理。

### 验证

- `xcodebuild test -only-testing:EasydictTests/MarkdownRendererTests`：27 项通过。
- 临时解析检查覆盖表头、数据行、未配对反引号和转义竖线。
- 实机结果卡片使用本机固定流式响应，确认表头和数据行都正确分列并保留反斜杠。
- `git diff --check` 通过，代码审查未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/MarkdownBlockParser.swift`

### 后续事项

- None

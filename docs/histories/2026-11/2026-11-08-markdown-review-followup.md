## 2026-11-08 | 任务：修复 Markdown 审查发现

**Links:** [PR #1375](https://github.com/tisfeng/Easydict/pull/1375) · [执行计划](../../exec-plans/completed/2026-11/2026-11-08-markdown-review-followup.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

修复 PR #1375 审查确认的其余四项 Markdown 渲染问题并实测。

### 变更

- 在表格体识别后续块边界，保留紧接表格的标题、列表和引用。
- 在行内预处理中保留价格、未配对反引号和自动链接，避免它们吞掉后续公式或改变链接地址。

### 设计意图

保留现有块解析和 Foundation 行内解析流程，针对边界判断补齐已复现的场景。

### 验证

- `xcodebuild test -only-testing:EasydictTests/MarkdownRendererTests`：27 项通过。
- 临时渲染探针：13 项通过，含数字开头的公式、成对反引号、表格中的公式及其后的分隔线。
- 实机验证：用固定流式响应复现四项场景，检查实际结果卡片并截图。右键「拷贝链接」精确返回原始 URL。
- `git diff --check` 通过，复审未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/MarkdownBlockParser.swift`
- `Easydict/Swift/Feature/Markdown/MarkdownInlineRenderer.swift`

### 后续事项

- None

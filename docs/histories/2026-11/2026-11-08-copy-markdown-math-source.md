## 2026-11-08 | 任务：修复选中公式后复制 TeX

**Links:** [PR #1375](https://github.com/tisfeng/Easydict/pull/1375)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

修复选中渲染后的公式时复制只得到附件占位符的问题，并实测两种复制入口和右键查询。

### 变更

- 在 Markdown 结果标签的 Copy 动作中识别选区里的公式附件，并通过已有的选区序列化逻辑写入纯文本 TeX。

### 设计意图

让键盘快捷键与右键菜单在共同的 Copy 入口还原 TeX。普通文本仍由 AppKit 处理，右键查询继续使用已有的源码还原逻辑。

### 验证

- `xcodebuild test -only-testing:EasydictTests/MarkdownRendererTests`：27 项通过。
- 实机验证：固定流式响应中的公式经 ⌘C 和右键「拷贝」后，剪贴板均精确等于 `$E=mc^2$`。点击右键查询后，新查询的输入框和本机服务请求都包含相同的 TeX。
- `git diff --check` 通过，代码审查未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/MarkdownLabel.swift`

### 后续事项

- None

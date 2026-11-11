## 2026-11-11 | 任务：在原文工具栏添加 Markdown 按钮

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-11-input-markdown-toggle.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

原文含 Markdown 且全局渲染设置开启时，在原文工具栏显示与译文卡一致的按钮。

### 变更

- 在原文复制按钮旁复用 Markdown 切换按钮。
- 复用 Markdown 解析规则识别可预览的内容，关闭全局设置时退出预览并隐藏按钮。

### 设计意图

让用户在原文工具栏内发现并切换 Markdown 预览。编辑器保留原始文本。

### 验证

- 常规构建运行了 SwiftFormat，27 项 Markdown 测试通过。
- 实测普通文本隐藏按钮。Markdown 源码可预览并切回，关闭全局设置后按钮隐藏。
- 复核按钮可见性、预览状态、内容更新及布局。Git 差异检查通过。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`

### 后续事项

- None

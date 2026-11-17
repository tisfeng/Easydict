## 2026-11-11 | 任务：修复公式预览背景色

**Links:** [公式渲染变更](2026-11-11-render-ocr-formulas.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

恢复公式预览态的原文框背景，使其与正式版输入框一致。

### 变更

- 原文滚动容器使用透明背景，由原文框绘制主题背景。

### 设计意图

原文预览与底部工具区共用原文框已有的背景色。

### 验证

- 常规 Debug 构建通过，SwiftFormat 正常执行。
- 以提供的公式 PNG 执行剪贴板翻译，并在深色模式下切换至源码。两种状态的正文和按钮区取样均为 `#303132`。
- `git diff --check` 通过。

### 受影响文件

- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`

### 后续事项

- None

## 2026-11-06 | 任务：添加理工科公式截图翻译

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-06-formula-screenshot-translation.md)、[#871](https://github.com/tisfeng/Easydict/issues/871)、[#1352](https://github.com/tisfeng/Easydict/issues/1352)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.0 / Xcode 27.2 (27B52)

### 用户请求

将定制版的公式截图翻译、Codex 模型与思考强度选择和本地自动保存设置提交上游。

### 变更

- 添加可选公式截图模式，将图片交给本机视觉 Codex 模型，显示原文及译文并保留可复制的 LaTeX。
- 在 Codex 卡片提供模型和思考强度菜单，在隐私设置控制本地保存。
- 更新中英文使用指南并覆盖公式渲染开关、分式居中和源码保留的回归测试。

### 设计意图

公式模式使用独立截图查询类型，普通截图继续走现有 OCR 和翻译服务。公式图像通过内存发送给
临时 Codex 会话。

### 验证

- Xcode 27.2 Debug 编译成功。Markdown、Codex 和 OCR/二维码的 6 个测试套件复测 100 项通过。
- 初次 OCR 高精度识别超时后快速回退，导致一项断言失败。上游原版 OCR/二维码对照 4 项通过，分支复测通过。
- 定制版手动检查了两种截图模式、公式排版、LaTeX 复制和模型与思考强度子菜单。

### 受影响文件

- `Easydict/Swift/Feature/Markdown/`
- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/objc/ViewController/`
- `EasydictTests/Feature/Markdown/MarkdownRendererTests.swift`
- `docs/user-docs/`

### 后续事项

- None

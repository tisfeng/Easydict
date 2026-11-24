## 2026-11-11 | 任务：取消 OCR 启动前排队的语言检测

**Links:** [PR #1391 审查评论](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4535617703)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复打字后立即启动剪贴板图片 OCR 时，排队的语言检测可能导致识别被取消的问题。

### 变更

- 在共用 OCR 入口取消尚未执行的文本语言检测。

### 设计意图

上一轮输入留下的延迟检测应随 OCR 接管输入而取消，避免半截识别文本触发源语言变化。

### 验证

- 临时回归验证在真实控制器入口排队检测，再启动剪贴板 OCR 并模拟首段到达。修复前检测回调读取了模拟文本，修复后回调未执行。
- Default 计划的 OCR 流式套件 11 项通过，包含上述临时验证。
- 原 Xcode 调试实例未退出，新构建的窗口未能打开。桌面快捷键与自动翻译流程未完成实测。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`

### 后续事项

- 桌面快捷键流程可在可用的独立调试实例中复验。

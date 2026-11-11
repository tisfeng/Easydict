## 2026-11-10 | 任务：编辑时结束普通 OCR 加载

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [审查线程](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4514126300) · [执行计划](../../exec-plans/completed/2026-11/2026-11-10-ocr-loading-on-edit.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

关闭键入和粘贴自动查询，分别验证普通 OCR 等待时的两种编辑操作。修复通过后更新原 PR 并回复和解决审查线程。

### 变更

查询视图在进入文字编辑状态前检查原图。如果存在截图，就停止输入区的加载动画。

### 设计意图

键入和粘贴都会触发同一个编辑回调。该回调清理视图状态，再由已有的动作切换清除原图。旧识别结果继续由请求校验丢弃。

### 验证

- Debug arm64 构建通过。`git diff --check` 通过。
- 在两个隔离 AppKit 宿主中，关闭键入和粘贴自动查询，分别通过实际编辑器执行键入和粘贴。操作前确认 OCR 尚未完成，操作后立即确认动画停止并检查新输入。真实 Vision 旧请求结束后，动画保持停止，编辑器与模型仍保留新输入，两次均未触发自动翻译。粘贴使用隔离剪贴板。
- 首次与交互宿主同时运行套件时，Vision 降级识别，有一项现有 OCR 文本断言失败。宿主退出后单独复跑，14 个套件的 185 项测试全部通过。

### 受影响文件

- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`

### 后续事项

界面验证使用隔离的 AppKit 编辑器和合成截图。

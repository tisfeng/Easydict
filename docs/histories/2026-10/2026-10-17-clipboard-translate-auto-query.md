## 2026-10-17 | 任务：剪贴板翻译始终自动查询

**Links:** None

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

点击「剪贴板翻译」直接自动翻译，不受「粘贴后自动查询」设置影响；普通粘贴保留原设置行为。

### 变更

- `pasteboardTranslate:` 的文本及图片 OCR 分支显式传入 `autoQuery:YES`，不再读取粘贴偏好。
- 普通粘贴回调和设置默认值保持不变。

### 设计意图

在明确的翻译入口表达自动查询意图，复用现有文本和 OCR 流程，避免改变共用查询方法或普通粘贴行为。
本次为单入口低风险修改，不创建独立执行计划。

### 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd"`：通过；使用当前 checkout 独立的 Agent DerivedData。
- 使用 `review` 技能审查基线 `af5b654f2890341a48f32237118ad2a686ea8f9d` 到工作树的任务差异：未发现有效 finding；当前入口参数修改已足够，无需修改共享方法。
- 手动代码检查：文本及图片入口启用自动查询，普通粘贴仍读取 `autoQueryPastedText`；构建后源码摘要未变化。
- 未新增或扩写测试；现有测试未直接覆盖该入口，未运行无关测试；未进行菜单点击的运行时验证。

### 受影响文件

- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`
- `docs/histories/2026-10/2026-10-17-clipboard-translate-auto-query.md`

### 后续事项

- 可在关闭「粘贴后自动查询」时手动确认菜单文本翻译、图片 OCR 翻译，以及普通粘贴行为。

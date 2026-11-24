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

## 2026-10-18 | 调整：剪贴板图片遵循 OCR 自动查询设置

### 用户请求

剪贴板图片遵循「图片 OCR 后自动查询」，纯文本直接翻译，普通粘贴继续遵循原设置。

### 变更与设计意图

- 图片分支读取 `autoQueryOCRText`，与截图翻译保持一致；OCR 识别后是否查询由该参数控制。
- 文本分支继续传入 `autoQuery:YES`，普通粘贴继续读取 `autoQueryPastedText`。
- 更新注释，将直接自动查询的说明限定在文本分支；保持单入口修改，无需独立计划。

### 验证

- 环境：`macOS 27.0.1 / Xcode 27.2 (27B5019j)`。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd"`：通过，复用当前 checkout 的独立 Agent DerivedData。
- `git diff --check`：通过。
- 使用 `review` 技能审查基线 `f7dbb50ca863ab4d1be12fc2430db0eff62e30b3` 到工作树的任务差异：未发现有效 finding；核对图片参数传递、OCR 完成后的查询条件、文本入口和普通粘贴回调，当前方案足够且无需修改共享流程。
- 构建后源码摘要保持一致；现有测试无直接覆盖该入口的用例，未新增、扩写或运行无关测试。
- 未进行菜单点击及 OCR 的运行时验证。

### 后续事项

- 可分别开关 OCR 自动查询选项，确认剪贴板图片识别后的行为；同时确认纯文本直接查询与普通粘贴设置行为。

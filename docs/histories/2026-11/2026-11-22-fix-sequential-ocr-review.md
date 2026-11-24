## 2026-11-22 | 任务：修复联合 OCR 审查问题

**Links:** [PR #1403](https://github.com/tisfeng/Easydict/pull/1403)、[执行计划](../../exec-plans/completed/2026-11/2026-11-22-fix-sequential-ocr-review.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复截图 OCR 与翻译联合请求的审查问题，将同类修复归入同一提交并逐组验证。

### 变更

- 按 Unicode 标量解析流式 JSON，并按 UTF-8 字节校验前缀。
- 跟踪联合请求状态，隔离卡片折叠与查询取消，清除失效请求的加载状态，避免替换选区按钮串用。
- 失败时显示错误并保留已发布内容；原文未完成时重发图片，原文已完成时重试文本翻译。
- 核对译文语言方向，补记联合译文的服务使用量，清理相关编译及 lint 警告。

### 设计意图

保持截图内容与本次请求绑定。卡片可以独立折叠，失败时以原文是否已完成决定重试入口；当前语言方向与图片请求不一致时走既有文本路径。

### 验证

- `xcodebuild test` 的默认 OCR 定向测试最终 14 项通过；替换请求、原文完成时取消、等待过程中失效、语言及分发用例各有真实服务通过记录。
- 真实请求曾间歇返回无效 JSON；同一构建的相关单独复测通过。DeepSeek 最终公式样例 3 次通过；Codex 3 次识别准确性未通过，断言保留。
- 手动检查：对照固定脱敏图片检查了原生控件导出的原文/译文截图；前台折叠、替换选区切换和断网重试未完成手动验收。

### 受影响文件

- `Easydict/Swift/Feature/OCR/OCRTranslationProgress.swift`
- `Easydict/Swift/Model/OCRTranslationRequest.swift`、`DetectManager.swift`
- `Easydict/Swift/Service/Model/QueryResult.swift`
- `Easydict/Swift/Service/OpenAI/StreamService.swift` 及相关扩展
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m` 和结果视图
- `EasydictTests/Feature/OCR/` 的现有测试

### 后续事项

- 前台实测折叠/展开与断网重试。继续跟踪 Codex 模型对公式下标和参考编号的识别准确性。

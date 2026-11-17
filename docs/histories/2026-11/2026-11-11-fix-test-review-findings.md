## 2026-11-11 | 任务：修复 OCR 与服务测试审查问题

**Links:** [PR #1391 审查线程](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4534846896) · [执行计划](../../exec-plans/completed/2026-11/2026-11-11-fix-test-review-findings.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

逐项修复上一轮审查指出的 OCR 测试失败、空服务结果通过和 MDict 缺配置通过。

### 变更

- OCR 测试模型等待主队列派发初始语言偏好，再设定测试语言。
- 全服务验证拒绝空白输出，按结果类型检查译文、词典 HTML 或有道释义。
- 外部 MDict 验证用 Swift Testing 条件 trait 报告缺少路径的跳过原因。

### 设计意图

测试模型沿用实际偏好初始化顺序。服务验证按调用返回的内容判断结果。外部词典校验仍用磁盘文件和实际解析器。

### 验证

- 默认计划运行 OCR 流式、免配置服务和 MDict 单元测试，32 项通过。
- 在本机 Auto/Auto 偏好下额外重复三轮 OCR 流式套件，10 项均通过。
- 本机环境计划单跑外部 MDict。缺少路径时报告 1 项跳过。提供临时 MDX/MDD 文件时 1 项通过，执行释义与资源读取断言。
- `git diff --check` 通过。

### 受影响文件

- `EasydictTests/Feature/OCR/OCRStreamingTests.swift`
- `EasydictTests/Service/ServiceTests.swift`
- `EasydictTests/Service/MDictReaderTests.swift`

### 后续事项

- 本次验证覆盖相关用例，未运行完整 Default 或需要本机配置的全部服务。

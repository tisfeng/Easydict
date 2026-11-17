## 2026-11-11 | 任务：修复 OCR 构建警告

**Links:** [测试审查修复](2026-11-11-fix-test-review-findings.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复 StreamService 类型体长度警告和 OCR 测试中两条 AnyClass 推断警告。

### 变更

- 将私有 OCR 图片编码方法移入 StreamService 同文件扩展。
- 给 OCR 重试测试中的两个 Objective-C 类对象补充显式 AnyClass 类型。

### 设计意图

保留图片编码方法的实例调用与原有实现，通过同文件扩展拆出独立职责。

### 验证

- 两个文件的严格 SwiftLint 检查零违规，Xcode 构建日志中未再出现三条目标警告。
- Default 计划的 OCR 流式套件 10 项通过。
- LocalEnvironment 的真实 DeepSeek 公式识图单测通过。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `EasydictTests/Feature/OCR/OCRStreamingTests.swift`

### 后续事项

None

## 2026-09-29 | 任务：修复 Apple OCR Sendable 捕获警告

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

修复 `AppleOCREngine` QR 检测闭包捕获非 `Sendable` `self` 的编译警告。

### 变更

- 将 QR payload 规范化 helper 改为 `private static`，闭包及现有去重路径调用静态方法，不再引用引擎实例。
- 未新增或修改测试；复用现有 QR OCR 测试套件验证结果语义。

### 设计意图

payload 规范化只依赖字符串，不需要访问 `AppleOCREngine` 状态。将 helper 设为静态方法消除 `@Sendable` 闭包对非 `Sendable` 实例的捕获，同时保留原有换行规范化和去重行为。

### 验证

- `BuildTools/.build/release/swiftformat --lint Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift --config .swiftformat`：通过，0/1 文件需要格式化。
- `xcrun swiftc -frontend -parse Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`：通过。
- `git diff --check`：通过。
- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS,arch=arm64' -derivedDataPath <checkout-derived Easydict-Agent> -only-testing:EasydictTests/OCRQRCodeTests EASYDICT_RELEASE_PACKAGING=YES`：QR OCR 测试 4/4 通过；`.xcresult` 构建结果为 `succeeded`，`warningCount=0`。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `docs/histories/2026-09/2026-09-29-fix-apple-ocr-sendable-capture.md`

### 后续事项

- None

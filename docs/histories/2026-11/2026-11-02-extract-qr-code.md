## 2026-11-02 | 任务：抽取独立 QRCode 类

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-02-extract-qr-code.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

### 用户请求

参考 Scoco，将二维码相关逻辑从 AppleOCREngine 提取到独立类。

### 变更

- 新增同目录 `QRCode.swift`，集中 modern/legacy 检测、去重、结果构造与内容追加。
- AppleOCREngine 持有 QRCode 实例；QR-only 回退前仍重置 textProcessor，内部多语言重试继续跳过重复二维码检测。
- 规范化 helper 改为 QRCode 私有实例方法，移除原文件的 String extension。
- 同步 Xcode group、文件及应用 target Sources 引用；现有测试保持原样。

### 设计意图

沿用 Scoco 的职责边界，遵循 Easydict 当前实例成员规则采用 final class。保留 Easydict 的任务取消、普通检测错误降级、原始 payload、去重和 mergedText 重建语义，不同步 Scoco 的观测几何或截图交互。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:EasydictTests/OCRQRCodeTests`：退出码 0；xcresult summary 为 Passed，4 项通过、0 失败、0 跳过。
- SwiftFormat lint（两个生产 Swift 文件）：通过，0 文件需格式化。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`、`git diff --check`：通过。
- 手动检查：按 review 技能对初始 HEAD `3fce1a81056bf220583a85ced33800d889693c42` 与最终生产文件审查；取消检查、VisionError 映射、legacy utility QoS、fallback reset、两轮 OCR 的追加顺序和工程引用均保留，无有效 finding。
- 构建日志包含 SwiftCompile “exit code 0 but produced no further output” 诊断及 bridging header 弃用警告；实际 xcodebuild 和 xcresult 均通过。
- 运行前后未发现存活的 Easydict 应用实例；未执行 Release、UI 或 macOS 13/14 运行验证。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/QRCode.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-11/2026-11-02-extract-qr-code.md`
- `docs/histories/2026-11/2026-11-02-extract-qr-code.md`

### 后续事项

- None

## 2026-11-11 | 任务：通过 Xcode Test Plan 运行真实 Codex OCR

**Links:** [真实公式 OCR 测试](2026-11-11-live-formula-ocr-test.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

移除真实 Codex OCR 测试的环境变量门槛。

### 变更

- 删除真实 Codex OCR 用例的环境变量条件，并用 XCTest 将其作为独立测试用例供计划选择。
- 共享 Scheme 使用默认计划保留已有测试排除项，并排除真实 Codex OCR。
- 非默认 CodexOCR 计划只运行真实公式 OCR 用例，可通过 Xcode 或 `xcodebuild test -testPlan CodexOCR` 选择。

### 设计意图

由 Xcode Test Plan 选择测试。选中真实服务用例后直接调用 Codex。

### 验证

- 用 `build-for-testing` 生成两个计划的运行配置。CodexOCR 计划实际调用 Codex 并通过一项测试。
- 默认计划的运行配置包含 Codex OCR 排除项，定向运行 OCRFormulaImageTests 的两项离线测试通过。
- 两个计划的 JSON、共享 Scheme 的 XML 及 Git 差异检查通过。

### 受影响文件

- `EasydictTests/Feature/OCR/OCRFormulaImageTests.swift`
- `EasydictTests/Default.xctestplan`
- `EasydictTests/CodexOCR.xctestplan`
- `Easydict.xcodeproj/xcshareddata/xcschemes/Easydict.xcscheme`

### 后续事项

- None

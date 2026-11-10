## 2026-11-11 | 任务：用真实公式图验证 OCR

**Links:** [公式 OCR 测试](../../../EasydictTests/Feature/OCR/OCRFormulaImageTests.swift)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

将提供的公式截图加入 OCR 测试，并使用真实 Codex 服务验证识别结果。

### 变更

- 将原图打包到测试 target。Apple OCR 和 Codex OCR 共用该图片。
- 移除返回固定响应的模拟服务用例。Codex 用例核对参考编号、行内公式和带编号的分式。

### 设计意图

离线回归验证 Apple OCR。真实服务验证通过显式环境变量启用，使用本机 Codex 配置。

### 验证

- 使用 `TEST_RUNNER_EASYDICT_RUN_LIVE_CODEX_OCR=1` 精确运行 OCRFormulaImageTests，三项测试通过。
- 默认模式下两项测试通过，真实 Codex 用例跳过。
- 工程文件解析、原图字节比较和 Git 差异检查通过。

### 受影响文件

- `EasydictTests/Feature/OCR/OCRFormulaImageTests.swift`
- `EasydictTests/Resources/OCRImages/ocr-en-formula.png`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- None

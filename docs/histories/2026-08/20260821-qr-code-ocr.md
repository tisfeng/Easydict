## 2026-08-21 | Task: 恢复 OCR 二维码内容识别

**Links:** GitHub issue `#967`

### User request

恢复 OCR 对二维码内容的识别，并保持现有文字 OCR 流程稳定。

### Changes

- 使用 Apple Vision 提取二维码 payload，支持纯二维码、文字与二维码混合及多个二维码。
- 对二维码内容进行规范化去重，同时保留返回内容的原始值。
- 纯二维码结果复用现有输入框、复制、OCR 预览和 HTTP OCR 输出路径。
- 更新中英文 OCR 用户文档，并补充行为测试。

### Design intent

二维码检测作为 Apple OCR 的附加能力运行。检测失败时继续返回原文字 OCR；文字 OCR 失败但二维码有效时返回二维码内容。内部多语言重试不重复执行二维码检测。

### Validation

- `git diff --check`：通过。
- 静态检查：确认 Vision 的 `.qr` symbology 和 `payloadStringValue` 支持当前最低系统版本；检查普通 OCR、静默 OCR、OCR 预览及 HTTP OCR 共用结果路径。
- 按用户要求未运行 build、test、app 或 formatter。

### Affected files

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/OCRTextProcessor.swift`
- `EasydictTests/Feature/OCR/`
- `docs/user-docs/en/GUIDE.md`
- `docs/user-docs/zh/GUIDE.md`

### Follow-ups

- 由 CI 验证构建与测试结果。

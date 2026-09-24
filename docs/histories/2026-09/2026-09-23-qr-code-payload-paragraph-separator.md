## 2026-09-23 | 任务：二维码内容改用段落分隔常量

**Links:** [Easydict PR #1277](https://github.com/tisfeng/Easydict/pull/1277)

### 执行上下文

- **Agent Name:** `root`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

把上一个提交里直接写的 `"\n\n"` 改成引用 `OCRConstants.paragraphSeparator`，修复后重写该
提交的提交信息。

### 变更

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift` 中
  `makeQRCodeOnlyResult` 与 `appendQRCodePayloads` 两处 `joined(separator:)` 改为引用
  `OCRConstants.paragraphSeparator`。
- 重写上一条本地提交（未推送）的提交信息以反映常量引用。
- 新增本文档。

### 设计意图

`OCRConstants` 已经定义 `paragraphSeparator = "\n\n"`，二维码内容的分段语义与它一致，直接引用
常量可以避免重复字面量，并让段落分隔的定义保持单一来源。此次只替换取值方式，拼接结果与对外
行为不变。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/OCRQRCodeTests -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Easydict-Temporary`：
  Test Succeeded，二维码 suite 4 个用例全部通过。
- 手动检查：`git diff --check` 通过；文件中不再存在硬编码的 `"\n\n"` 拼接。
- 环境限制：默认 DerivedData 被本机正在运行的 Xcode 构建占用，且本机 SwiftLint 异常缓慢，
  因此沿用临时 DerivedData 并以 `EASYDICT_RELEASE_PACKAGING=YES` 跳过 Format/Lint 阶段。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `docs/histories/2026-09/2026-09-23-qr-code-payload-paragraph-separator.md`

### 后续事项

- None

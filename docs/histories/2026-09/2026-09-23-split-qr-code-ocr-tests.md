## 2026-09-23 | 任务：拆分二维码 OCR 测试到独立文件

**Links:** [Easydict PR #1277](https://github.com/tisfeng/Easydict/pull/1277)

### 执行上下文

- **Agent Name:** `root`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

把 PR #1277 新增的二维码 OCR 测试从 `OCRImageTests.swift` 单独提取到一个测试文件，先给出
方案；确认方案 A 后执行。

### 变更

- 新增 `EasydictTests/Feature/OCR/OCRQRCodeTests.swift`：迁入 4 个二维码测试（纯二维码、
  文字 + 二维码、多二维码去重、无二维码时不回归）以及 `makeOCRImage`、`makeQRCodeImage`
  两个内存生成测试图片的私有 helper。
- `EasydictTests/Feature/OCR/OCRImageTests.swift` 删除上述测试与 helper，并移除不再使用的
  `CoreImage`、`CoreImage.CIFilterBuiltins` import。
- `Easydict.xcodeproj/project.pbxproj` 登记新文件的 `PBXFileReference`、`PBXBuildFile`、
  OCR 分组条目与 `EasydictTests` 的 Sources build phase 引用。
- 新增本文档。

### 设计意图

二维码测试使用内存生成的图片，与依赖 `ocr-images` 资源的多语言 OCR 测试在关注点和 fixture
构造方式上都不同。拆为独立 suite 后，二维码场景可以单独运行并继续扩展（例如后续补充 CRLF
payload、多语言二维码等），同时沿用 `.ocr`、`.integration` 标签，过滤行为保持不变。本次只
移动代码位置，断言、payload 字面量与图片构造参数均未修改。

### 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：OK。
- `EASYDICT_RELEASE_PACKAGING=YES xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/OCRQRCodeTests -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Easydict-Temporary`：
  Test Succeeded，新 suite 4 个测试全部通过（1.73s）。
- `EASYDICT_RELEASE_PACKAGING=YES xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -only-testing:EasydictTests/OCRImageTests/testOCRPerformanceOne -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Easydict-Temporary`：
  Test Succeeded，裁剪后的原 suite 仍可构建与执行。
- 手动检查：`git diff --check` 通过；新文件没有超过 140 字符的行。
- 环境限制：默认 DerivedData 被本机正在运行的 Xcode 构建占用（`build.db` locked），因此按
  `docs/agents/build-and-test.md` 的回退规则改用临时 DerivedData；本机 SwiftLint 单文件即需
  数分钟，测试使用 `EASYDICT_RELEASE_PACKAGING=YES` 跳过 Format/Lint 阶段，未取得整仓 lint
  结论。

### 受影响文件

- `EasydictTests/Feature/OCR/OCRQRCodeTests.swift`
- `EasydictTests/Feature/OCR/OCRImageTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/histories/2026-09/2026-09-23-split-qr-code-ocr-tests.md`

### 后续事项

- 未运行整仓 SwiftLint；如需完整 lint 结论可在空闲环境单独补跑。

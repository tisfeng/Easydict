## 2026-09-28 | 任务：修复 SwiftUI aspect ratio 警告

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

修复 `OCRImageView` 和 `ScreenshotOverlayView` 中 SwiftLint 的 `legacy_swiftui_aspect_ratio` 警告。

### 变更

- 将两个图片视图中的 `.aspectRatio(contentMode: .fit)` 替换为 `.scaledToFit()`。

### 设计意图

使用 SwiftUI 专用的等比例适配 modifier，保留 `.fit` 布局行为并消除旧式写法警告，不调整 SwiftLint 规则。

### 验证

- `swiftlint lint --no-cache --config .swiftlint.yml Easydict/Swift/Service/Apple/AppleOCREngine/View/OCRImageView.swift Easydict/Swift/Feature/Screenshot/Screenshot/ScreenshotOverlayView.swift`：SwiftLint 0.65.1 报告 2 个文件 0 条违规。
- `cd BuildTools && swift run -c release swiftformat --lint ../Easydict/Swift/Service/Apple/AppleOCREngine/View/OCRImageView.swift ../Easydict/Swift/Feature/Screenshot/Screenshot/ScreenshotOverlayView.swift --config ../.swiftformat`：2 个文件均通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd" -disableAutomaticPackageResolution EASYDICT_RELEASE_PACKAGING=YES`：Build Succeeded；SwiftLint 对目标文件另行定向验证。
- `git diff --check`：通过。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/View/OCRImageView.swift`
- `Easydict/Swift/Feature/Screenshot/Screenshot/ScreenshotOverlayView.swift`
- `docs/histories/2026-09/2026-09-28-fix-swiftui-aspect-ratio-warning.md`

### 后续事项

- None

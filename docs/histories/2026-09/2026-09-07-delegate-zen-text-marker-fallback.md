## 2026-09-07 | 任务：委托 Zen Text Marker 回退给 SelectedTextKit

**Links:** [SelectedTextKit PR #10](https://github.com/tisfeng/SelectedTextKit/pull/10)

### 用户请求

在同步 Easydict 后续更新后，使用 SelectedTextKit 2.6.7 的 Text Marker 回退，并删减 Easydict 中重复的 Zen 划词实现。

### 变更

- 将 SelectedTextKit 的 SwiftPM 最低版本与锁定版本升级到 2.6.7。
- 删除 Easydict 的 Zen 专用焦点元素重解析、Text Marker API 调用和 Accessibility 策略回退。
- 将 Zen 加入应用专属的 selectable-text 检查放行表，使 AXWindow 能进入 SelectedTextKit 的回退流程。
- 当 Zen 的 Accessibility/Text Marker 路径未取得文本时，允许其自动进入既有强制取词流程，并在该流程的二次开关检查中同样按 Zen 专属规则放行，不依赖全局“强制取词”开关。

### 设计意图

SelectedTextKit 负责 Accessibility 文本获取及其 Text Marker 回退；Easydict 保留对该库 `SelectedTextManager` 的单一调用，避免两处实现相同回退逻辑。Zen 的 `AXWindow` 仅在自动划词入口按 bundle ID 放行；依赖库未取得文本时，Easydict 复用已有强制取词流程作为 Zen 专属的最后回退。

### 验证

- `git diff --check`：通过。
- `BuildTools/.build/arm64-apple-macosx/release/swiftformat --lint`：通过，5 个 Swift 文件均无需格式化。
- Xcode SwiftPM 解析：最终工程 checkout 的 SelectedTextKit 为 `2.6.7`，提交为 `5e70e14fad11b541db45f51ddd570aa79fc8d729`。
- `xcodebuild build`：失败于本地环境缺少 `Masonry/Masonry.h`，尚未形成完整应用构建结论。
- 独立审查：未发现确定的产品代码缺陷；已确认删除的 Zen helper 不会遍历 Accessibility 元素树，2.6.7 的库回退会在原生文本为空或抛错时尝试 Text Marker。
- 手动检查：Zen 的 `AXWindow` 曾在入口被跳过；添加专属放行后，关闭全局“强制取词”设置时，自动划词仍可经 Zen 专属回退取得选中文本。

### 受影响文件

- `Easydict/Swift/Utility/SystemUtility/FocusedElementInfo.swift`
- `Easydict/Swift/Utility/SystemUtility/SystemUtility+AX.swift`
- `Easydict/Swift/Utility/SystemUtility/SystemUtility+Selection.swift`
- `Easydict/Swift/Utility/SystemUtility/SystemUtility.swift`
- `Easydict/Swift/Utility/EventMonitor/Workflow/SelectionWorkflow.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcworkspace/xcshareddata/swiftpm/Package.resolved`

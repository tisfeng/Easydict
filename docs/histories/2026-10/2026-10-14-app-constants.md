## 2026-10-14 | 任务：统一 App 级常量到 AppConstants

**Links:** [2026-10-14-ezconst-swift-cleanup.md](2026-10-14-ezconst-swift-cleanup.md)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.0 (27A266a)`

### 用户请求

用户认为 `NetworkConstants`、`EasydictRepo` 等只含一两个值的常量类型过度拆分，要求结合项目现有常量
重新设计 Swift 常量方案，并按方案执行，类型命名为 `AppConstants`。

### 变更

- `SharedConstants.swift` 重命名为 `AppConstants.swift`，改为 `@objcMembers final class`，按 App、
  Repository、Network、Query 分组。
- 并入 `EasydictRepo` 与 `NetworkConstants` 并删除这两个文件；属性改为领域前缀命名，如
  `repoName`、`networkTimeoutInterval`，`easydictTranslateShortcutName` 改为 `translateShortcutName`。
- 迁移 `EZBundleId`、`EZDebugBundleId` 为 `AppConstants.bundleID`、`debugBundleID`，`EZWindowManager.m`
  改用新常量。
- 更新 Swift 与 Objective-C 调用方、`project.pbxproj`，并在 `coding-guidelines.md` 记录常量放置规则。
- 后续修复：`userAgent` 字面量拆为两段拼接，消除 SwiftLint `line_length` 警告，值不变。

### 设计意图

App 级常量集中在一个类型中，用 MARK 分组代替多个小类型；使用扁平属性和 `@objcMembers`，使
Objective-C 仍可访问。模块专用常量（如 `OCRConstants`）和同类外部标识集合（`AppBundleIDs`）保留
独立。`EZConst.h` 中仅 Objective-C 使用的布局、窗口和查词常量随对应文件迁移，届时优先成为模块私有常量。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：成功。
- `git diff --check`：通过。
- `swiftlint lint AppConstants.swift`（项目 SwiftLint 二进制）：无违规。
- 手动检查：未运行 App。

### 受影响文件

- `Easydict/Swift/Utility/Constants/AppConstants.swift`
- `Easydict/Swift/Utility/Constants/EasydictRepo.swift`（删除）
- `Easydict/Swift/Utility/Constants/NetworkConstants.swift`（删除）
- `Easydict/App/EZConst.h`
- `Easydict/Swift/` 下的常量调用方
- `Easydict/objc/` 下的 `EZAudioPlayer.m`、`EZURLSchemeHandler.m`、`EZWebViewTranslator.m`、`EZWindowManager.m`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/agents/coding-guidelines.md`

### 后续事项

- `EZConst.h` 剩余的 Objective-C 专用常量与 `EZOpenSettingsNotification` 随对应文件迁移。

## 2026-10-14 | 任务：清理 AppWindowID 并迁移 EZConst 中的网络常量

**Links:** [2026-10-14-easydict-repo-constants.md](2026-10-14-easydict-repo-constants.md)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.0 (27A266a)`

### 用户请求

确认 `AppWindowID` 未被使用后移除，并将 `EZConst.h` 中适合迁移的常量改为 Swift，包括
Swift 与 Objective-C 共用的 `EZNetWorkTimeoutInterval`。

### 变更

- 删除未被引用的 `AppWindowID.swift`。
- 新增 `@objcMembers` 的 `NetworkConstants`，提供 `timeoutInterval` 与 `userAgent`；Swift 服务和
  Objective-C 的 `EZAudioPlayer`、`EZURLSchemeHandler`、`EZWebViewTranslator` 改用它。
- `EZQuickLinkButtonUpdateNotification` 改为 `Notification+Name.swift` 中的字符串字面量，值不变。
- 删除 `EZConst.h` 中的 `EZUserAgent`、`EZNetWorkTimeoutInterval`、`EZQuickLinkButtonUpdateNotification`
  和未使用的 `EZGetClipboardTextDelayTime`，并同步 `project.pbxproj`。

### 设计意图

只迁移 Swift 专用、未使用或两侧共用的常量；仅 Objective-C 使用的布局等常量保留在 `EZConst.h`，
随对应 Objective-C 文件迁移。`userAgent` 与超时同属网络配置，因此一起放入 `NetworkConstants`，
而不是职责混杂的 `SharedConstants`。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：成功。
- `git diff --check`：通过。
- 手动检查：未运行 App。

### 受影响文件

- `Easydict/App/EZConst.h`
- `Easydict/Swift/Utility/Constants/NetworkConstants.swift`
- `Easydict/Swift/Utility/Constants/AppWindowID.swift`（删除）
- `Easydict/Swift/Utility/Constants/SharedConstants.swift`
- `Easydict/Swift/Utility/Extensions/Notification/Notification+Name.swift`
- `Easydict/Swift/Service/{Bing,DeepL,Google,NiuTrans,OpenAI,Youdao}/`
- `Easydict/objc/Service/AudioPlayer/EZAudioPlayer.m`
- `Easydict/objc/Service/WebViewTranslator/EZURLSchemeHandler.m`
- `Easydict/objc/Service/WebViewTranslator/EZWebViewTranslator.m`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- `EZOpenSettingsNotification` 等仅 Objective-C 或由 Objective-C 发送的常量待对应文件迁移时处理。

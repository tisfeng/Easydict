## 2026-11-20 | 任务：修复查询窗口快捷菜单“打开应用设置”无反应

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 26.6.2 / Xcode 27.2 (27B52)`

### 用户请求

查询窗口右上角快捷菜单里点击“打开应用设置”没有反应，定位并修复。

### 原因

`EZTitlebar` 的菜单项只发出 `EZOpenSettingsNotification`，设置窗口实际会打开，但查询窗口不会激活应用，
Easydict 仍在后台，设置窗口出现在当前前台应用的窗口后面，看起来像没有反应。菜单栏菜单的“设置…”在打开前
调用了 `activateApp()`，所以不受影响。

在测试宿主中对比（先让访达成为前台应用）：只发通知时设置窗口可见但不是 key window，应用未激活、前台仍是访达；
先激活再发通知时设置窗口成为 key window，Easydict 成为前台应用。

### 变更

- `EZTitlebar` 的“打开应用设置”在发出通知前激活应用。
- `NSApplication.activateApp()` 标记为 `@objc`，供 Objective-C 调用。

### 验证

- `xcodebuild build`（Debug，Xcode 27.2）：通过。
- 临时测试（未提交）在测试宿主中先激活访达，再调用 `EZTitlebar` 的 `goToSettings`：设置窗口可见且为 key window，
  前台应用变为 Easydict。修改前同样条件下设置窗口不是 key window，前台仍为访达。

### 受影响文件

- `Easydict/objc/ViewController/View/Titlebar/EZTitlebar.m`
- `Easydict/Swift/Service/Apple/AppleOCREngine/View/OCRWindowManager.swift`

## 2026-11-20 | 任务：为复制操作添加 Copied 提示

**Links:** https://github.com/tisfeng/Easydict/issues/1410

### 执行上下文

- **Agent Name:** `Buddy`
- **Model:** `claude-opus-6`
- **Environment:** `macOS 26.5 / Xcode 26.5 (17F42)`

### 用户请求

实现用户自己提出的 #1410：点击复制按钮后显示 "Copied" 提示。今天只处理这一项，不改其他 issue。

### 变更

- 恢复 `String.copyAndShowToast(_:)` 中被注释掉的 toast 调用，改为在主线程显示本地化的 `copy.copied`，位置设在鼠标附近。
- 在 `Localizable.xcstrings` 新增 `copy.copied`，覆盖 en、es、ja、sk、ur、zh-Hans、zh-Hant 七个现有 locale。
- 新增本 history 记录。

### 设计意图

复用已有 `EZToast` 以及所有复制入口已经在调用的 `copyAndShowToast(_:)`，不新增抽象、不改各调用点，也不改变复制本身的行为和空字符串守卫。提示放在鼠标附近，贴近触发复制的按钮或光标位置。

### 验证

- `xcrun swiftc -frontend -parse Easydict/Swift/Utility/Extensions/String/String+Convenience.swift`：通过。
- `xcrun swiftc -typecheck /tmp/easydict-toast-shim.swift`：通过，确认 `EZToast.showText(_:toastPostion:)` 与 `.mouse` 的调用形式可编译。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过；`copy.copied` 七个 locale 齐全。
- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd"`：未完成。SwiftPM 解析阶段卡在拉取依赖（vapor 等）；本机 HTTPS 代理返回 502，改用 SSH 重写后 `ls-remote` 正常但 `clone` 挂起，未产生构建产物。
- 手动界面验证：未执行，因为没有本次构建的实例；toast 的实际位置与显示效果待在 Xcode 本地复验。
- 未运行测试：改动仅涉及 UI 反馈，没有对应的可测试业务行为；按规则未新增或扩写测试。

### 受影响文件

- `Easydict/Swift/Utility/Extensions/String/String+Convenience.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/histories/2026-11/2026-11-20-show-copied-toast.md`

### 后续事项

- 在网络正常的机器上做 Debug 构建并实测三条入口：查询框复制按钮、结果卡片复制按钮、⌘⇧C 快捷键；确认 "Copied" toast 出现在鼠标附近并自动消失。
- 实测通过后再 push 分支并开 PR 关联 #1410。

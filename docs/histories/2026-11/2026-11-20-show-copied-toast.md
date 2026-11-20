## 2026-11-20 | 任务：为复制操作添加 Copied 提示

**Links:** https://github.com/tisfeng/Easydict/issues/1410

### 执行上下文

- **Agent Name:** `Buddy`
- **Model:** `claude-opus-6`
- **Environment:** `macOS 26.5 / Xcode 26.5 (17F42)`

### 用户请求

实现用户自己提出的 #1410：点击复制按钮后显示 "Copied" 提示。今天只处理这一项，不改其他 issue。

### 变更

- 恢复 `String.copyAndShowToast(_:)` 中被注释掉的 toast 调用，在主线程显示本地化的 `copy.copied`，沿用 `EZToast.showText` 默认的右上角位置。
- 在 `Localizable.xcstrings` 新增 `copy.copied`，覆盖 en、es、ja、sk、ur、zh-Hans、zh-Hant 七个现有 locale。
- 新增本 history 记录。

### 设计意图

复用已有 `EZToast` 以及所有复制入口已经在调用的 `copyAndShowToast(_:)`，不新增抽象、不改各调用点，也不改变复制本身的行为和空字符串守卫。位置沿用 `EZToast.showText` 的默认右上角，和原注释代码及其他 `showText` 调用保持一致，避免引入额外定位行为。

### 验证

- `xcrun swiftc -frontend -parse Easydict/Swift/Utility/Extensions/String/String+Convenience.swift`：通过。
- `xcrun swiftc -typecheck /tmp/easydict-toast-shim.swift`：通过，确认 `EZToast.showText(_:)` 的调用形式可编译。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过；`copy.copied` 七个 locale 齐全。
- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd"`：未完成。SwiftPM 解析阶段反复卡在拉取依赖；`-disablePackageRepositoryCache` 后能拉完 5 个包，但随后代理连接再次挂住，18 分钟无进展，未产生构建产物。
- 手动界面验证：未执行，因为没有本次构建的实例；默认右上角 toast 的实际显示待在 Xcode 本地复验。
- 未运行测试：改动仅涉及 UI 反馈，没有对应的可测试业务行为；按规则未新增或扩写测试。

### Review 响应

PR #1412 的 Codex review 指出 `.mouse` 定位属于新增的用户可见行为，解析和 shim typecheck 无法证明它出现在正确位置并自动消失。由于本机无法完成 app 构建，按要求回退到 `EZToast.showText` 的默认右上角位置，不再引入未验证的光标定位行为；该位置与仓库现有 `showText` 调用一致。

### 受影响文件

- `Easydict/Swift/Utility/Extensions/String/String+Convenience.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/histories/2026-11/2026-11-20-show-copied-toast.md`

### 后续事项

- 在网络正常的机器上做 Debug 构建并实测三条入口：查询框复制按钮、结果卡片复制按钮、⌘⇧C 快捷键；确认 "Copied" toast 出现在默认右上角并自动消失。
- 已在 PR #1412 中回应 Codex review；若维护者仍要求光标附近提示，再补 `.mouse` 并附实测截图。

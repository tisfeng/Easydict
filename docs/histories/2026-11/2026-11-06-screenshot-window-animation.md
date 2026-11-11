## 2026-11-06 | 任务：禁用截图窗口动画

**Links:** 回归提交 `d8dcfd332cbadd9c5858387f62c270ceb7654cb7`；[前台焦点改动记录](2026-11-06-screenshot-foreground-focus.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

修复截图时的明显画面跳动，参考 Scoco 禁用截图窗口动画，保留不抢前台焦点的行为，验证和 review 后本地提交。

### 变更

- 在截图遮罩显示前设置 `window.animationBehavior = .none`，禁用 AppKit 自动显示和隐藏动画，并添加原因注释。
- 保留非激活 NSPanel、非 key/main 窗口、键盘隔离、鼠标框选和现有结果窗口处理路径。
- 单一窗口配置修复，不新建执行计划；未新增或扩写测试。

### 设计意图

`d8dcfd332` 将遮罩由 NSWindow 改为 NSPanel，却沿用了由 AppKit 按窗口类型推断动画的默认配置。
截图遮罩铺有整屏背景，窗口动画会影响整屏画面的观感。参考 Scoco
`aad2738bb6c432ab30020410bc6b86607c98516f` 的 `ScreenshotOverlayWindow` 配置显式禁用动画，
保留前台焦点设计。采用 [Apple animationBehavior](https://developer.apple.com/documentation/appkit/nswindow/animationbehavior-swift.property)
规定的窗口级控制，不扩大到全局动画或 SwiftUI 视图行为。

### 验证

- SwiftFormat lint、SwiftLint strict、`git diff --check`：通过。
- 签名 Debug/macOS arm64 `xcodebuild build`：通过，产物 `codesign --verify --deep --strict` 通过。
  使用当前 checkout 的独立 agent DerivedData、既有锁定包缓存，以及本机 Automatic / Apple Development 签名；未修改工程设置。
  `EASYDICT_RELEASE_PACKAGING=YES` 跳过全仓格式化 phase，变更 Swift 文件单独 lint 通过。
- 使用 review 技能由主 Agent 自审基线 `d8dcfd332cbadd9c5858387f62c270ceb7654cb7` 到任务差异，
  覆盖唯一遮罩创建入口、多屏循环、显示前配置、隐藏路径、非激活及非 key/main 配置和未变的键盘过滤与结果回调，未发现有效 finding。
  窗口级配置与 Scoco 一致，已足够解决本次自动动画控制，无需引入新的窗口抽象。
  构建后与提交前复验源码 SHA-256 为 `1e303c4acd2c093f1f6bee403f79dadd2a81cb9f3c227b74f43c0a2f0f59c424`。
- 现有测试没有覆盖截图遮罩窗口动画，本次未运行不相关的 OCR 或查询测试。
- 实际画面与焦点验收未执行；用户现有调试实例未退出或替换，不将静态检查和构建视为实际截图验收。

### 受影响文件

- `Easydict/Swift/Feature/Screenshot/Screenshot/Screenshot.swift`
- `docs/histories/2026-11/2026-11-06-screenshot-window-animation.md`

### 后续事项

- 使用新构建实测截图开始、取消及完成时的画面，并确认原应用继续保持前台焦点。

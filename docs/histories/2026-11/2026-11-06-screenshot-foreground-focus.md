## 2026-11-06 | 任务：截图期间保留前台焦点

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-06-screenshot-foreground-focus.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

参考 Scoco 精简适配截图：框选期间不抢前台焦点，保留键盘隔离和现有结果窗口行为。
不新增测试；验证和 review 后本地提交，不合入 dev、不 push。

### 变更

- 截图遮罩改为非激活、非 key/main 的 NSPanel，移除应用激活和结束后的延迟焦点恢复。
- 新增截图专用主动键盘过滤，仅申请 keyDown/keyUp；D/Esc 保留原动作，其他普通输入被消费，
  系统应用/空间切换快捷键取消截图并放行。
- 已消费按键处理重复、配对松键、跨会话残留和过滤器中断恢复；窗口动作异步执行并校验会话。
- 不可用时在非激活遮罩内显示本地化鼠标操作提示，不恢复会穿透的全局键盘观察器。
- 鼠标追踪使用 activeAlways tracking area，接受首次鼠标操作；截图清理先于结果回调，延迟截图绑定会话。
- 清理窗口管理器的截图恢复参数，保留翻译、静默 OCR、OCR 预览各自的结果处理路径。
- 登记新 Swift 源码的工程引用，补齐现有七种语言提示；未新增或扩写测试。

### 设计意图

非激活面板保留原应用焦点，主动事件过滤负责键盘隔离。只采用 Scoco 必要的事件生命周期机制，
不引入标注、取色、撤销和录屏分支，也不扩大通用划词监听的权限和职责。
来源为 Scoco `ccc75800774fdf757e1157cbe581cc3b87d29558`、
`42d9b72a0e2562af9062465cf1a26d71d90b33e3`，核对源结束 SHA
`aad2738bb6c432ab30020410bc6b86607c98516f`。
API 依据为 Apple 的 [nonactivatingPanel](https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel)、
[Monitoring Events](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html)
和 [CGEventTapCallBack](https://developer.apple.com/documentation/coregraphics/cgeventtapcallback)。

### 验证

- 默认签名构建因缺少所选 provisioning profile 失败；未修改工程配置。
- 关闭签名的 Debug/macOS arm64 build-for-testing 通过；随后使用本机既有开发证书/profile，
  仅在命令行选择 Automatic / Apple Development 的签名构建通过，未请求远端签名更新。
- 构建使用独立 agent DerivedData；跳过全仓格式化 phase，对五个变更 Swift 文件单独执行
  SwiftFormat lint 和 SwiftLint strict，均通过。
- 现有 OCRQRCodeTests、OCRTextProcessingTests、QueryModelCancellationTests、LocalizationTests：
  xcresult 确认 19 passed、1 failed、0 skipped。
- 唯一失败 `OCRQRCodeTests/testOCRWithoutQRCode()` 触发 accurate OCR 的 5 秒超时降级。
  单独复跑失败；对首次写入前的精确基线 `a4d2681132b8687702f561f389dfd8cdfc119020`
  使用相同配置和隔离环境构建/运行后，同一断言、实际文本和预期文本完全相同。未改动 OCR 引擎或测试。
- 新键盘过滤器以 `arm64-apple-macos13.0` 独立 typecheck 通过；工程 plutil、String Catalog JSON、
  新源码引用与七种 locale 检查、`git diff --check` 通过。
- 用户最终选择只做可行界面检查和静态验证，不使用 CGEvent 注入。界面工具访问现有调试实例持续超时，
  没有退出或替换原实例；没有将焦点保持、键盘事件过滤、长按松键、跨屏或权限降级记为实机通过。
- 恢复任务产物后最终开发签名 build-for-testing 通过；八个生产/工程/资源文件与此前验证快照一致。
- 使用 review 技能审查基线到任务工作树的完整 diff（含新增过滤器），覆盖非激活面板、首次鼠标操作、
  输入消费及松键、中断恢复、会话失效、权限失败降级、清理与三种结果路径，未发现确认 finding。
  审查方式为主 Agent 自审；此结论不替代未执行的实机验收。
- 审查摘要 `ff3d0f260e93a9a2ab64e8a64d4d47f23768964be2ddea7991fbbebc13a6b199`
  在最终构建与交付前按文件哈希复验一致。

### 受影响文件

- `Easydict/Swift/Feature/Screenshot/Screenshot/` 中的窗口、视图、状态、事件处理和新增键盘过滤器。
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- 同任务执行计划与本记录。

### 后续事项

- 真实系统输入、焦点保持、多屏/全屏、长按与松键、权限失败和真实 tap 中断恢复仍需后续实机验收。
- 现存 OCR golden 失败未在本任务修复。
- 仅本地提交，不合入 dev、不 push；未新增或扩写测试。

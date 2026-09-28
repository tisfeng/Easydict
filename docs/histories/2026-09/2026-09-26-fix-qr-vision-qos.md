## 2026-09-26 | 任务：调整二维码检测的 Vision 执行优先级

**Links:** [Apple Dispatch QoS 规则](https://developer.apple.com/documentation/dispatch/dispatch_block_flags_t/dispatch_block_enforce_qos_class)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

修复截图 OCR 触发的 Thread Performance Checker 警告：User-initiated 线程等待 Utility 线程。

### 变更

- `detectQRCodePayloads(on:)` 显式使用 Utility 全局队列和 Utility work item，并设置
  `.enforceQoS`；添加注释说明 Vision 内部同步等待 CIContext 工作的调度原因。
- 新增本记录；未新增或修改测试。

### 设计意图

Xcode 的现有诊断栈从二维码检测的 `VNImageRequestHandler.perform` 进入
`VisionCoreCIContextsHandler.waitAndGetAvailableContextReturnError:`。限定调整这条调用路径，
使外层任务的指定 QoS 与本次观察到的内部 Utility 工作匹配，沿用 continuation 防重复恢复、
检测失败返回空数组及二维码 payload 处理逻辑。

这是一项针对 Vision 同步接口的调度规避，不消除框架内部等待；`.enforceQoS` 也不构成系统
优先级提升的上限。繁忙环境下的响应时间和原始运行时警告需要实测。

### 验证

- `git diff --check`：通过。
- `swiftformat --lint Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`：通过。
- `xcrun swiftc -frontend -parse Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`：通过。
- SwiftLint 使用 `--use-script-input-files --config .swiftlint.yml --strict --no-cache`，
  只检查修改的 Swift 文件：0 violations。
- `xcodebuild build-for-testing -workspace Easydict.xcworkspace -scheme Easydict
  -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64'
  -only-testing:EasydictTests/OCRQRCodeTests -skipPackageUpdates -jobs 4
  EASYDICT_RELEASE_PACKAGING=YES`：`TEST BUILD SUCCEEDED`。
  `$agent_dd` 按当前 checkout 派生，遵循构建隔离规则；跳过构建阶段的整仓 Format/Lint，
  以以上单文件检查覆盖本次修改。
- 停止 Xcode 中正在运行的调试 App 后，在同一 DerivedData 使用
  `xcodebuild test-without-building` 运行现有 `OCRQRCodeTests`，两轮均为 4/4 通过，
  覆盖纯二维码、文字混合、多码去重和无二维码图片。
- 测试通过 `TEST_RUNNER_DYLD_INSERT_LIBRARIES` 追加线程性能检查库；dyld 日志确认
  `libRPAC.dylib` 已加载。两轮日志未出现原优先级反转警告，xcresult 的
  `runtimeWarnings` 均为空；这不能替代原始交互场景的复验。
- 首轮 suite 耗时 71.370 秒，其中首个用例 70.273 秒；日志显示该用例在 CGImage 转换后
  约 0.34 秒已进入后续文字识别，长等待发生于文字识别阶段。复跑 suite 耗时 1.494 秒，
  首个用例 0.522 秒。未做修改前后的耗时对照，不据此宣称性能提升。
- `review`：以 `f19e283fa6ae35cbf709111b815ff8714f40be0d` 为基线，核对本任务源码差异、
  调用链、错误路径、continuation gate 和现有测试断言，未发现有效 finding。
  当前局部调度调整足以覆盖已定位的调用入口；扩大到全部文字 OCR 或迁移 Vision API
  会增加验证范围，本次无需采用。审查后源码摘要复验一致。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `docs/histories/2026-09/2026-09-26-fix-qr-vision-qos.md`

### 后续事项

- 在 Thread Performance Checker 开启时复验原始截图交互场景及繁忙环境下的响应时间；
  本次未运行跨 macOS 版本验证或整仓测试。

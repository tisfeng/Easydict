## 2026-09-29 | 任务：移植二维码检测 QoS 与完成时机修复

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-29-port-qr-detection-completion.md)、[此前调度修复](2026-09-26-fix-qr-vision-qos.md)、[Apple Dispatch QoS](https://github.com/apple-oss-distributions/libdispatch/blob/main/dispatch/block.h#L79-L89)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

检查 Easydict 是否存在与 Scoco 相同的 QR 检测调度问题，并执行局部移植。实际运行测试由用户自行完成。

### 变更

- 将 Scoco 提交 `630cb7536f9f59df61f9ab692e7d937c39081768` 的核心逻辑适配到 `detectQRCodePayloads(on:)`。
- 请求创建、同步执行与结果读取全部放入 userInitiated GCD 工作项，替换 utility 队列与 enforceQoS。
- 使用无 completion handler 的 Vision 请求，正常结果、空结果与异常路径在 `perform` 返回后统一恢复一次 continuation。
- 保留二维码原文、归一化去重、结果合并与失败返回空数组的行为。
- 保留旧版文字 OCR 使用的通用 `ContinuationGate`；其余生产源码与基线一致。

### 设计意图

二维码检测是用户等待中的 OCR 操作，使用明确的后台 userInitiated 调度。Vision SDK 的
`VNRequest.h` 说明 completion handler 早于同步 `perform` 返回，因此延后交付结果，避免下一阶段文字 OCR 提前进入。
仅替换 QR 路径，保留现有文字识别 API 选择、预热和通用 gate，减少移植范围。

历史警告位于 Vision 内部 CIContext 等待路径。Dispatch 的 inheritQoS 优先采用目标队列的 QoS，
不能把仅更换该 flag 当作根因修复。此次调整也不保证消除系统框架内部的所有等待，仍须实际运行确认。

### 验证

- `git diff --check`：通过。
- `BuildTools/.build/release/swiftformat --lint Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`：通过，0/1 文件需要格式化。
- `xcrun swiftc -frontend -parse Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`：通过。
- SwiftLint 使用 `--use-script-input-files --config .swiftlint.yml --strict --no-cache`：0 violations。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64' -skipPackageUpdates -jobs 4 EASYDICT_RELEASE_PACKAGING=YES`：`BUILD SUCCEEDED`。`$agent_dd` 按 checkout 派生，遵循仓库隔离规则；跳过构建阶段的整仓 Format/Lint，以前述单文件检查覆盖此次变更。
- Review：对照基线 `f50244578ec67f2131b4770a88371b8d19e74834` 审查完整差异、调用链、错误路径和现有测试断言，未发现有效 finding；编译与审查后源码摘要一致。
- 实现方式判断：局部函数适配保留了现有架构与结果语义，无需新增辅助类型；用户等待中的同步工作明确在后台执行，结果在请求返回后统一交付。
- 按用户要求未运行 `OCRQRCodeTests` 或实际 Xcode Run，不声称原始警告已消失。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `docs/exec-plans/completed/2026-09/2026-09-29-port-qr-detection-completion.md`
- `docs/histories/2026-09/2026-09-29-port-qr-detection-completion.md`

### 后续事项

- 用户复测原截图 OCR 入口，确认识别结果及 Thread Performance Checker 警告。
- 如警告继续出现，收集新等待栈及低 QoS 生产线程堆栈，再评估框架资源竞争路径。

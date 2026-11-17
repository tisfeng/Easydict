## 2026-11-02 | 任务：迁移现代 Vision 二维码检测 API

**Links:** [DetectBarcodesRequest](https://developer.apple.com/documentation/vision/detectbarcodesrequest) ·
[VisionError.requestCancelled](https://developer.apple.com/documentation/vision/visionerror/requestcancelled%28_%3A%29) ·
[执行计划](../../exec-plans/completed/2026-11/2026-11-02-modern-qr-detection.md) ·
[既有 OCR golden 差异](2026-11-02-ocr-accurate-retry.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

### 用户请求

按方案在 macOS 15+ 使用 `DetectBarcodesRequest`，旧系统保留原实现；运行现有测试并对比
已知 golden 失败，确认没有新增回归、完成 review 后创建本地提交，不 push。
旧修复分支放回主工作区，当前 worktree 使用新分支承接二维码改进。

### 变更

- 二维码检测入口按 macOS 15 分流；新分支直接 await `DetectBarcodesRequest.perform(on:)`，
  只请求 `.qr`，读取 `BarcodeObservation.payloadString`。
- macOS 13–14 保留 `VNDetectBarcodesRequest`、同步 `VNImageRequestHandler` 及 utility QoS。
  continuation 将错误传回统一入口处理，对外仍为普通错误记录日志并继续文字 OCR。
- 两个路径共用空内容过滤和按规范化 key 去重，保留首次出现的原始 payload 与结果顺序。
- 调用前后检查任务取消，`CancellationError` 和新 API 的 `VisionError.requestCancelled`
  均向上传播，避免将取消当作普通检测失败。
- 保留只检测一次、二维码与文本合并、文字识别失败时返回二维码的现有调用路径；不改变 OCR
  模型、识别语言、超时策略或测试预期。

### 设计意图

使用原生 async API 简化新系统异步桥接，兼容旧系统；新旧路径只返回字符串，共享业务处理，
避免两套去重和错误策略漂移。新 API 不包装额外 GCD 或 detached task，旧同步 API 的 QoS
仍显式设置。三个局部 helper 足以表达职责，未引入通用并发适配框架。

### 验证

- 初始提交为 `0f05fb13466c9793897d102a2f0d26dec21396e9`；当前分支为
  `refactor/modern-qr-detection`，主工作区保留 `fix/vision-ocr-fallback` 与该原提交。
- 当前 worktree 使用独立 DerivedData，前后均为同一 Development 签名、arm64 目标和测试选择，
  bundle ID 保持项目配置。两轮各运行 12 个现有测试：

| 测试范围 | 原实现 | 新 API 分流后 |
| --- | --- | --- |
| `TaskTimeoutTests` | 5 通过 | 5 通过 |
| `OCRQRCodeTests` | 4 通过 | 4 通过 |
| `OCRImageTests/testAutoLanguageOCR()` | 1 失败 | 1 失败 |
| `OCRImageTests/test()` | 1 失败 | 1 失败 |
| `OCRImageTests/testEnglishOCR()` | 1 失败 | 1 失败 |

- 21 条 golden 失败消息逐条完全一致：日文 `ocr-ja-text-4.png`；中文
  `ocr-zh-text-bitcoin.png`；英文 `ocr-en-paper-1.png` 至 `ocr-en-paper-13.png`、
  `ocr-en-text-4.png`、`ocr-en-text-5.png`、`ocr-en-text-letter-338.png`、
  `ocr-en-text-list-1.png`、`ocr-en-text-two-columns-1.png`、`ocr-en-text-two-columns-2.png`。
- 日文实际输出两轮均为 `今日は世界自然保護デー`，预期均为 `今日 世界自然保護`。
  样例、实际输出与 golden 均未变化，所选组无新增失败；整体测试退出码仍为 65，不能称全绿。
- 修改后签名 Debug build 退出码 0；Swift parser、SwiftFormat lint 与差异空白检查通过。
- Swift 5 API 类型检查以 macOS 13 为最低部署目标通过，包含新请求调用与取消 case 匹配。
- 使用 review 审查完整 diff、availability、两条检测路径、错误与取消传播、payload 处理及
  continuation 生命周期，未发现新增有效 finding。源码在审查后复验，未产生漂移。
- 未新增或扩写测试。现有四个二维码用例在 macOS 27.0.1 运行，旧分支与 macOS 15 首发版本
  的实际运行尚未验证；异常与取消路径包含静态审查证据。
- 用户原有应用实例保留，测试宿主已退出；所有代码改动与本地提交仅在新任务分支，不 push。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `docs/exec-plans/completed/2026-11/2026-11-02-modern-qr-detection.md`
- 本 history。

### 后续事项

- 在 macOS 13–14 和 macOS 15 对应环境完成兼容性运行验收。
- 既有日文、英文与中文 golden 差异独立处理，不通过本次修改重写预期。

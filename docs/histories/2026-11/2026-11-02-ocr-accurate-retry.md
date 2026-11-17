## 2026-11-02 | 任务：修复 OCR 降级语言匹配并移除启动预热

**Links:** [PR #1382](https://github.com/tisfeng/Easydict/pull/1382) ·
[执行计划](../../exec-plans/completed/2026-11/2026-11-02-ocr-accurate-retry.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

### 用户请求

每次 OCR 优先尝试 accurate，失败后仅对本次请求降级一次 fast；修复 fast 的语言匹配并完整
移除 OCR warm-up。现有日文 golden 失败先记录，确认没有新增回归、完成 review 后创建本地
提交，不 push。不新增或扩写测试。

### 变更

- 删除进程级永久不可用状态，accurate 执行槽由底层 operation 通过 defer 释放。
  后续请求先有界等待再尝试 accurate；旧请求尚未退出时不启动更多并行 accurate 工作。
- 取消继续传播；fast 降级最多执行一次，空结果不再触发日文配置的第二次 fast 请求。
- fast 使用 `Locale.Language.isEquivalent(to:)` 匹配偏好与支持列表，保留偏好顺序及 Vision
  返回的受支持值；明确指定语言的支持判定也使用等价关系，避免错误启用自动检测。
- 删除启动调用、合成预热图片、modern/legacy 预热实现以及四处 Xcode 引用。
  accurate 的超时常量、锁与执行状态迁入引擎的 private 区域。
- 更新本 history 并归档同任务计划。已有 inference entitlement 继续保留。

### 设计意图

真实请求按需初始化 Vision，避免预热与真实识别竞争；可用性按每次请求决定，并将底层工作
生命周期与调用方 deadline 分离。语言匹配使用 Foundation 的等价 API，不自行维护 BCP-47
转换规则，也不将匹配修复描述为 fast 新增了中文或日文模型。

### 验证

- 初始提交为 `5489191e9e6c238ccd890d23a68885ae18c97bd1`。前一阶段已实现 accurate 恢复；
  本轮以该未提交状态作为语言匹配和预热移除的基线，在同一 Development 签名配置下前后对比。
- 两轮均运行相同的 12 个现有测试，结果均为 9 个通过、3 个 golden 测试失败：

| 测试范围 | 修改前 | 修改后 |
| --- | --- | --- |
| `TaskTimeoutTests` | 5 通过 | 5 通过 |
| `OCRQRCodeTests` | 4 通过 | 4 通过 |
| `OCRImageTests/testAutoLanguageOCR()` | 1 失败 | 1 失败 |
| `OCRImageTests/test()` | 1 失败 | 1 失败 |
| `OCRImageTests/testEnglishOCR()` | 1 失败 | 1 失败 |

- 逐条比较 21 条失败消息，实际识别输出、golden 预期与失败样例完全相同，无新增失败：
  日文 `ocr-ja-text-4.png`；中文 `ocr-zh-text-bitcoin.png`；英文 `ocr-en-paper-1.png` 至
  `ocr-en-paper-13.png`、`ocr-en-text-4.png`、`ocr-en-text-5.png`、`ocr-en-text-letter-338.png`、
  `ocr-en-text-list-1.png`、`ocr-en-text-two-columns-1.png`、`ocr-en-text-two-columns-2.png`。
- 日文两轮实际输出均为 `今日は世界自然保護デー`，golden 为 `今日 世界自然保護`。
  英文和中文差异也已在修改前复现，本次没有修改预期或把这些失败计为通过，未进一步归因其根因。
- 修改后签名 Debug `xcodebuild build` 退出码为 0；Swift parser、SwiftFormat lint、工程
  `plutil -lint`、`git diff --check` 通过。测试进程退出码 65，整体测试仍不是全绿。
- Foundation/Vision API 探查确认：旧严格匹配得到 0 项，新等价匹配按偏好顺序保留六种 fast
  支持语言；英语支持判定正确，日文仍不受支持。未新增测试或生产代码测试 hook。
- 现行源码、测试与工程无 OCR warm-up 残留；用户原有应用实例保留，测试宿主已退出。
- 使用 review 审查完整任务 diff、引擎状态/取消/超时边界、语言设置、启动与工程引用，未发现
  新增有效 finding。源码与同配置回归支持当前实现；未覆盖旧系统真机和全部模型冷启动组合。
- 用户已明确接受记录既有 golden 失败，在所选回归组未新增失败并完成 Review 后创建本地提交。

### 受影响文件

- `Easydict/App/EasydictApp.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine+WarmUp.swift`（删除）
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-11/2026-11-02-ocr-accurate-retry.md`
- 本 history。

### 后续事项

- 日文、英文和中文既有 golden 差异作为独立后续事项处理，本轮保持测试与预期原样。
- fast 不支持的语言仍可能在 accurate 不可用时失败；规范化匹配无法扩充模型能力。

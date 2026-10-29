## 2026-10-29 | 任务：修复 Vision OCR 间歇性失败

**Links:** [Issue #1376](https://github.com/tisfeng/Easydict/issues/1376) ·
[执行计划](../../exec-plans/completed/2026-10/2026-10-29-vision-ocr-fallback.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.2 / Xcode 27.1 (27A9275)`

### 用户请求

调查本机 Easydict 在 macOS 27 上偶发无法完成 OCR 的日志和源码，在独立 worktree 中修复并验证；
随后明确授权在已知签名测试限制下创建本地提交和 GitHub PR。

### 变更

- 日志确认 modern Vision accurate OCR 的冷启动可能耗时 88–179 秒，且启动预热与真实请求会并发
  占用同一 ANE 路径；macOS 26+ 因此停用 speculative warm-up，旧系统保留原 legacy warm-up。
- modern accurate 请求增加 10 秒 deadline 和进程级单路执行策略；超时、API 错误或空结果后切换
  有相同 deadline 的 fast 请求，避免继续堆积可能忽略取消的 ANE 工作。
- fast 路径根据其实际支持列表过滤语言，关闭语言校正，并在指定语言不受支持时启用自动检测。
- Debug 与 Release entitlement 增加 macOS 27 后台 inference 权限，覆盖静默截图后应用退到后台的场景。
- 静默 OCR 先处理错误，再复制文本或显示成功 toast，避免失败时复制空字符串并误报成功。

### 设计意图

正常环境仍优先使用 accurate，保留现有多语言识别质量；只有 accurate 路径在 deadline 内不可用时
才牺牲精度切换 fast，从而把无限或分钟级等待变成有界响应。跳过新系统 warm-up 避免预热本身
占住 ANE；进程进入 degraded 状态后不再反复启动 accurate，重启应用后仍会重新探测。

### 验证

- `git diff --check`、Xcode Swift parser、两个 entitlement 的 `plutil -lint`：通过。
- 仓库固定 SwiftFormat 0.63.0 对两个 Swift 文件执行 lint：通过，0/2 文件需要格式化。
- Xcode 27.1 无签名 Debug build：通过；本机没有 `swiftlint`，构建脚本只产生非阻塞 warning。
- `OCRImageTests` 完整编译并运行：unsigned 测试宿主的 accurate 请求在 10 秒后按设计切换 fast，
  证明调用有界；fast 不满足现有多语言 golden 输出，共 70 个断言失败。
- 临时 Mach-O 和测试 App 均能签入并回读 inference entitlement；受限 entitlement 的 ad-hoc 测试
  App 被 macOS 拒绝启动，且 `security find-identity` 返回 0 个有效 identity，因此无法完成生产签名
  下的 OCR golden 验证。用户获知并明确授权继续提交和创建 PR。
- 使用 review 技能审查完整生产差异：补上 fast deadline，修正 warm-up pending 时过早使用 fast 的
  质量回归，并恢复 macOS 25 及更早系统的 legacy warm-up 边界；最终复审无其他有效 finding。

### 受影响文件

- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`
- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine+WarmUp.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `Easydict/App/Easydict.entitlements`
- `Easydict/App/Easydict-debug.entitlements`
- 本 history 与归档执行计划。

### 后续事项

- 使用具备目标 entitlement 的正式 Development 或发布签名重新运行 `OCRImageTests`，确认 accurate
  在后台测试宿主中不会超时，并人工核对 accurate 不可用时 fast 对主要语言的可接受性。

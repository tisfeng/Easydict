## 2026-11-09 | 任务：脱敏 Bing 朗读日志并修复跨窗口截图状态

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [执行计划](../../exec-plans/completed/2026-11/2026-11-09-cross-window-screenshot-review.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

修复 Bing 朗读原文日志、跨窗语言变化导致普通 OCR 卡住、公式历史语言对不正确的问题。验证后更新 #1391 并逐条处理审查意见。

### 变更

- Bing 朗读诊断仅记录请求状态。
- 在模型、图片、动作、输入和请求标识都仍匹配时，若 OCR 只因共享语言更改而失效，则向原窗口报告取消并结束加载。
- 公式截图历史从已完成的翻译结果读取源语言和目标语言。

### 设计意图

OCR 仍用请求标识保护更新的任务。只为仍归属原窗口的失效请求结束加载，保留原图以支持再次识别。历史记录的语言元数据与对应译文一起确定。

### 验证

- Debug arm64 构建成功。185 项现有测试分布在 14 个套件中，全部通过。`git diff --check` 通过。
- 关闭本地自动保存，选择 Bing，关闭有道优先并开启自动朗读。Vision 从合成截图识别了未缓存的英文词，实际 Bing 请求返回音频。检查隔离宿主的落盘日志，确认有 Bing 诊断，找不到测试原文。
- 同一隔离宿主中的两个 AppKit 窗口各用独立控制器和查询模型。A 正在执行普通截图 OCR 时，触发 B 的实际源语言选择回调。A 结束加载、保留原图，随后重试成功。
- A 以英语到简体中文开始公式截图，离线 Codex 协议桩暂停返回。B 将共享设置切到法语到德语后再释放结果，查询历史实际持久化的语言对仍为英语到简体中文。

### 受影响文件

- `Easydict/Swift/Service/Bing/BingService.swift`
- `Easydict/Swift/Model/DetectManager.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`

### 后续事项

双窗验证使用隔离 AppKit 窗口与实际语言选择回调。公式响应由离线协议桩控制时序。

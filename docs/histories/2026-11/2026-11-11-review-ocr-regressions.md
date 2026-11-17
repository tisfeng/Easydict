## 2026-11-11 | 任务：修复 OCR 审查回归

**Links:** https://github.com/tisfeng/Easydict/pull/1391；[执行计划](../../exec-plans/completed/2026-11/2026-11-11-review-ocr-regressions.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

一起处理六条开放审查讨论，核实过时的收藏语言问题；验证后更新原 PR 并逐条回复关闭，查询 CodeQL。DeepSeek API 密钥及其他凭据保留在本机。

### 变更

- 默认测试计划按整个 CodexFormulaImageTests、DeepSeekFormulaImageTests 类排除在线测试，独立 CodexOCR、DeepSeekOCR 计划继续可用。
- 图片编码辅助方法改为实例方法，遵循仓库约定。
- 手动原文预览/源码选择会在第一个公式出现前记录，后续流式公式继续尊重该选择；新截图仍重置。
- 程序化选中文字替换先取消旧 OCR、停止加载，再更新动作和文本，旧回调继续被请求门禁丢弃。
- 显式 OCR 重试始终保留继续翻译的意图，首次截图的自动查询偏好保持原值。
- 过时评论仍对应现存收藏路径：原逻辑读取共享语言偏好。收藏现在复用当前查询匹配结果的捕获语言；新输入不复用旧结果。
- 扩展现有 OCRStreamingTests，覆盖上述边界，并附固定输入的 AppKit 控件截图。

### 设计意图

沿用作者的可选 OCR 与共享公式架构，在既有入口处理状态和请求意图。收藏文本与语言来自同一个当前查询结果，在线测试通过独立计划运行。

### 验证

- `xcodebuild build-for-testing`：最终 Debug arm64 构建成功。
- `test-without-building`：14 个相关套件共 153 项回归通过。
- Xcode 默认测试实际枚举：两类共四项真实 Codex/DeepSeek 方法均位于禁用列表，默认启用列表含 495 项；本轮未运行全部 495 项。
- 独立 CodexOCR 两项与 DeepSeekOCR 两项真实测试均通过，验证增量输出、完成前数学附件、最终分式和上下标。
- 固定样例单次请求：Codex OCR 首段/完整 4.89/6.51 秒、翻译 4.22/6.60 秒（5 次未完成更新）；DeepSeek OCR 0.31/1.89 秒、翻译 0.80/1.41 秒（2 次未完成更新）。这些数据仅确认流式行为。
- 检查测试导出的 AppKit 原文控件截图：第一个公式前手动选择源码后仍显示源码；重置后的闭合公式可以提前显示分式。
- 选中文字替换使用真实控制器与受控延迟回调，验证加载结束、截图身份清除和旧输出被丢弃。收藏使用两个控制器共享偏好传播、真实标题栏收藏入口与持久化记录断言，恢复临时收藏及偏好。
- 重试测试在真实重试入口捕获 OCR 调用的继续翻译标志；这次未人工重做双窗口截图流程。
- 首次收藏测试因误用抽象服务基类退出；改用已有测试服务后最终全套通过。
- 最终代码审查及源码摘要复验通过，`git diff --check` 通过；比对本机真实凭据未发现待提交内容包含密钥，配置与运行日志均位于仓库外。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`
- `Easydict/objc/ViewController/View/Titlebar/EZTitlebar.m`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.h`、`.m`
- `EasydictTests/Default.xctestplan`
- `EasydictTests/Feature/OCR/OCRStreamingTests.swift`

### 后续事项

- 修复提交 `532bf3b6e4d1ae5ad9e43eb15c5be92308b29c7a` 已快进推送原 PR；六条评论均按远程 head 复核后回复、解决并读回验证，全量刷新为 34 条已解决、0 条开放。
- CodeQL 修复轮次 `42972836821` 已启动，范围检查成功、Swift 构建进行中，尚未给出最终分析结果；前一轮 `42968653967` 为 cancelled。
- 本记录的收尾归档仅修改文档，生产与测试源码保持在已验证的修复快照。最终安全检查与合并由 PR 最新工作流和维护者确认。

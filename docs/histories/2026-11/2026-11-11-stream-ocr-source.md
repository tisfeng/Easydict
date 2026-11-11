## 2026-11-11 | 任务：流式排版截图原文与译文

**Links:** https://github.com/tisfeng/Easydict/pull/1391；[执行计划](../../exec-plans/completed/2026-11/2026-11-11-stream-ocr-source.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

截图原文逐步显示，闭合公式提前排版，译文也流式输出；Codex 强度选项遵循本机实际模型能力。用户授权相关回归测试，并要求 Codex 测试后补跑 DeepSeek。

### 变更

- 先按用户要求将已有 13cc2360、efcd0360 两次本地提交追加原 PR，远程 head 确认为 efcd03602db65b0ec517dbd23bca5f003e8e1442。
- OCR 接口增加增量回调，Codex 转发既有 App Server 输出，DeepSeek/OpenAI 复用 SSE 传输。主线程有序消费，约 80ms 限制界面刷新；最终结果后才自动复制或启动翻译。
- 增量和完成回调均核对请求、模型、图片、动作、输入与语言；首段纯空白暂存，普通 OCR 保留一次返回。
- 原文复用共享 MarkdownLabel，公式闭合后提前排版，并尊重手动切换回 LaTeX 原文。译文本机 Codex 路径改用独立临时 App Server 线程，实现真实增量并保留取消与用量边界。
- 设置页读取本机 CLI 的 model/list，按选中模型显示强度。确认旧 minimal 不受 Luna 支持后改为 Low；有效选择、未知模型与读取失败时的已保存配置保留。
- 新增 OCR 流式、QueryView 公式预览及模型能力回归，独立真实计划覆盖 Codex 与 DeepSeek 的 OCR 和翻译。

### 设计意图

提前显示识别和翻译过程，沿用共享公式排版；识图与翻译继续采用独立请求。模型能力取自实际运行时，config.toml 只承载默认选项。OCR 服务列表保持原样，托管模式保留版本目录。

### 验证

- Debug arm64 build-for-testing 成功，14 个相关套件共 150 项回归通过；追加 DeepSeek 翻译测试后再次编译测试成功。
- CodexOCR 两项真实测试通过：OCR 首段 3.743s / 完整 5.314s；译文首段 3.157s / 完整 5.326s，6 次未完成更新。
- DeepSeekOCR 两项真实测试通过：OCR 首段 0.199s / 完整 1.016s；译文首段 0.774s / 完整 1.381s，2 次未完成更新。
- 四项真实测试通过最终分式与上下标断言；两项翻译测试在后续文字仍生成时已观察到数学附件。这些时间来自固定小图片与短文本各一次测试。
- QueryView 回归覆盖一个闭合公式与一个未闭合公式共存、后续闭合、LaTeX 复制、手动源文切换和重置。
- 本机菜单实测、截图检查为默认/Low/Medium/High/XHigh/Max，旧 minimal 自动保存为 Low。用户在真实论文窗口确认“公式提前排版，译文也会逐步出现”。
- 论文框选由用户完成；这里发送快捷键无法调出界面。菜单截图由 CUA 显示在对话中，当前工具未提供文件保存路径。OpenAI 与托管账户未进行本轮真实在线调用。
- 源码审查未发现有效阻塞项，已复验测试与源代码摘要。安装版生产代码摘要匹配当前工作区。

### 受影响文件

- `Easydict/Swift/Model/DetectManager.swift`
- `Easydict/Swift/Service/Model/QueryService.swift`
- `Easydict/Swift/Service/OpenAI/` 图片识别与共享传输
- `Easydict/Swift/Service/DeepSeek/DeepSeekService.swift`
- `Easydict/Swift/Service/CodexCLI/` 图片/译文增量及能力读取
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/CodexCLIServiceConfigurationView.swift`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.h`、`EZQueryView.m`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- OCR、DeepSeek、Codex 测试、真实测试计划与工程引用

### 后续事项

- 本次新增流式、提前公式排版及动态强度改动仅完成本地交付，原 PR 仍停在此前 efcd0360。

收尾核验：用户复测后当前 OCR 为 Codex；保留其选择，GPT-6 Luna / Low 与关闭本地自动保存保持有效。临时启动设置已恢复，三份本任务回退应用已清理，当前安装版签名和生产摘要检查通过。

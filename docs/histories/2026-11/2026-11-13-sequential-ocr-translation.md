## 2026-11-13 | 任务：单次图片请求顺序流式识图与翻译

**Links:** [上游建议](https://github.com/tisfeng/Easydict/pull/1391#issuecomment-6786692042)、[计划](../../exec-plans/active/2026-11-13-sequential-ocr-translation.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

整理为一次请求、原文后译文的顺序流式方案，提交独立 PR，附此前八组测速与 token 表格，并继续稳定性验证。

### 变更

- 基于 dev 30b53c9b，合并匹配配置的图像识别与翻译；使用独立 JSON 字段、转义安全的增量解码和有序 UI 事件。
- 原文完成时分发其他已启用翻译服务，匹配服务继续复用同一图片请求。Codex 的输出约束与 DeepSeek 的 JSON 模式仅作用于本次图片请求。
- 接入现有控制器、Markdown/公式、历史及复制逻辑，保留源文提取、关闭自动查询与非翻译模式的原有路由。
- 清空前保存已确认的识别语言，待检测的旧语言重新检测；校验输入、配置、语言、代次和图片身份，取消与替换隔离旧结果。
- 测速工具与本机原始产物保留在原分支/仓库外，本 PR 说明包含八组原始 token 均值和完整测量边界。

### 设计意图

采用原文后译文避免交叉输出通道串扰，同时允许完整原文提前交给其他服务。末尾强制刷新保证快速响应的最后一个闭合公式得到显示。配置和凭据只在内存比较；日志只记录固定错误类别。显示继续复用上游渲染。

### 验证

- `xcodebuild build-for-testing`：Debug arm64 成功。
- Default 定向回归：10 套件、84 项通过；覆盖 JSON 分块/转义、最终校验、服务匹配、Markdown、OCR、请求取消及 Codex 配置。
- LocalEnvironment 的 CombinedOCRTranslationTests：14 项通过，包括 Codex/DeepSeek 各三次双输出、多服务启动、自动与纠正语言、仅 OCR、取消/替换、两窗口模型、首段后粘贴等。
- 另九次 DeepSeek 响应均可完成 JSON 解码；一次译文网络单包归并仍在完成事件前发布，按协议行为判定流式。
- 原生原文预览与译文控件截图通过分式、上下标和编号检查，产物位于仓库外。前台快捷键框选受锁屏限制，本轮使用真实控制器入口与独立测试宿主。
- 多轮实测发现普通 OCR 与联合作用均可能多识别一个分母平方。额外幂次检查被显式记录为间歇性模型准确性问题，其他内容和流程断言保留硬性失败；此前双字段校验失败也保留记录。明确对象模板后重复验证通过，仍需更大样本。
- 代码审查：已修复手动识别语言丢失、旧检测语言复用，以及缺少本机配置时应跳过测试的问题。后续仅文档交付继续核验。

### 受影响文件

- `Easydict/Swift/Feature/OCR/`、`Easydict/Swift/Model/DetectManager.swift`、`Easydict/Swift/Model/OCRTranslationRequest.swift`
- `Easydict/Swift/Service/OpenAI/`、`Easydict/Swift/Service/Codex/`、`Easydict/Swift/Service/DeepSeek/DeepSeekService.swift`、`Easydict/Swift/Service/Model/QueryService.swift`
- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `EasydictTests/Feature/OCR/`、`Easydict.xcodeproj/project.pbxproj`

### 后续事项

创建并核验独立 PR 后归档计划。需要长论文、多栏、混合语言、复杂公式、弱网断流、长时间取消重试、前台双窗口及其他视觉模型验证；Release、Intel 和全量默认测试尚未覆盖。模型准确性与协议/界面稳定性分别衡量。

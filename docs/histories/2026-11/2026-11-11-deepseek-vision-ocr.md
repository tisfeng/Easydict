## 2026-11-11 | 任务：接入 DeepSeek 视觉 OCR

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-11-deepseek-vision-ocr.md)、[PR #1391](https://github.com/tisfeng/Easydict/pull/1391)、[官方 Vision 文档](https://api-docs.deepseek.com/guides/vision/)、[模型能力文档](https://api-docs.deepseek.com/api/list-models/)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

### 用户请求

为本机 PR1391 测试版的 OCR 服务选择接入 DeepSeek。用户另行明确允许同步更新旧能力断言并补充图片请求和模型限制测试。

### 变更

- DeepSeek 声明 OCR 能力，复用已有服务配置和共享图文转录流程。
- 图片请求使用用户消息中的文字与 image_url 内容块，沿用 endpoint、API key、模型及 thinking/reasoning_effort 设置。
- 接受官方 Flash 模型及已公开的旧 Flash 别名；V4 Pro 在发送图片前显示本地化的 Flash 选择提示。
- 原有文字翻译保持 role/content 字符串消息和流式请求；公式显示继续交给共享 Markdown 渲染。
- 更新七种现有语言的提示文案和能力断言，补充请求编码、关闭思考、缺少密钥、非视觉模型与旧别名测试。
- 添加显式选择的 DeepSeekOCR 真实识图计划，默认测试保持离线运行。

### 设计意图

识图能力沿用作者为 OCR 服务建立的扩展点。服务可独立负责截图转录，转录文本继续进入现有翻译和公式预览流程。Flash 的支持范围按当前官方文档及已配置账户的模型列表交叉核对。

### 验证

- `xcodebuild build-for-testing`：最终构建成功，项目格式和 lint 检查按原配置执行。
- `Default` 计划中的 DeepSeek、OCR、Codex 和 Markdown 相关测试：10 个套件共 139 项通过。
- `DeepSeekOCR` 计划：配置中的真实 DeepSeek Flash 成功识别 `ocr-en-formula.png`，保留 `EDLUNA-4736`、`p_7=53`、`R_8`、分式、`x_j^2+1`、根号和公式定界符。
- 真实模型列表确认：Flash 的 input_modalities 为 text/image；V4 Pro 为 text。
- 界面验收：本机高级设置中已出现并选中“DeepSeek 翻译”，OCR 说明包含新增服务；界面截图已检查。新增服务的真实识别由显式测试计划验证。
- 安装核对：应用内部名称沿用上游，更新唯一 PR1391 测试版；服务配置和关闭本地自动保存的状态保持有效。
- `git diff --check`、项目 plist 与测试计划 JSON 检查通过；本地审查未发现有效阻塞问题。

### 受影响文件

- `Easydict/Swift/Service/DeepSeek/DeepSeekService.swift`
- `Easydict/App/Localizable.xcstrings`
- `EasydictTests/Service/DeepSeek/DeepSeekOCRTests.swift`
- `EasydictTests/Feature/OCR/OCRFormulaImageTests.swift`
- `EasydictTests/DeepSeekOCR.xctestplan`
- `EasydictTests/Default.xctestplan`
- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcodeproj/xcshareddata/xcschemes/Easydict.xcscheme`

### 后续事项

- 官方新增可识图模型时，可基于模型能力元数据扩展本服务的 OCR 支持范围。
- 本次仅交付本机功能和本地提交，远程 PR 的更新可另行推进。

## 2026-11-06 | 任务：增加获取模型按钮与输入框的间距

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

为设置页面中紧贴模型输入框的“从云端获取模型”按钮增加间距。

### 变更

- 将支持的模型输入区域外层 VStack 的垂直间距从 0 调整为 8 pt。
- 保留按钮右对齐、右侧留白、可用性条件及获取模型行为。

### 设计意图

输入框与操作按钮在垂直方向留出清晰间隔，布局关系由两者的直接父容器统一控制。
这是单行、局部、低风险的布局修正，未创建执行计划或新增测试，也未进行独立 review 技能审查。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64' -disableAutomaticPackageResolution -skipPackageUpdates`：Debug 构建成功；使用本 checkout 的独立 Agent DerivedData。
- `git diff --check`：通过。
- 手动检查：核对用户截图、TextEditorCell 和父容器布局，确认间距只存在于模型输入区域与按钮之间；未在运行中的设置页面做视觉复验。
- 未运行测试：仅调整布局常量，不涉及可测试业务行为，未新增或扩写用例。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/StreamConfigurationView.swift`
- `docs/histories/2026-11/2026-11-06-model-fetch-button-spacing.md`

### 后续事项

- 在设置页确认 8 pt 间距的实际视觉效果。

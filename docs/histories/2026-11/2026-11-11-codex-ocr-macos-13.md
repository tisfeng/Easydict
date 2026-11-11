## 2026-11-12 | 任务：在 macOS 13 起启用内置 Codex OCR

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-11-codex-ocr-macos-13.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

让 Easydict 内置 ChatGPT 登录模式从 macOS 13 起支持截图 OCR。

### 变更

- 统一选择官方 0.153.4 组件，更新托管组件清单和加载校验，删除仅允许新版运行时进行 OCR 的错误分支及本地化。
- 保留官方包校验和账号目录。原来保存的 gpt-5.5 和推理强度仍在新版目录中。仅缓存旧组件的用户可从设置下载 0.153.4。
- 更新中英文使用指南和组件文档。

### 设计意图

内置模式直接调用 Codex。OCR 请求附带图片，shell 工具及 shell snapshot 均关闭。沿用已接入的图片协议和官方完整组件。

### 验证

- `xcodebuild test` 定向运行托管运行时、组件安装、账户和公式 OCR 四组测试，39 项通过。
- 检查最终 Debug 产物的部署下限为 13.0，托管清单同时包含 Apple Silicon 和 Intel 组件。JSON 和差异检查通过。
- 启动最终 Debug 产物，界面工具读取窗口超时，未取得 OCR 截图。验收后恢复原 Debug 产物。
- 使用 review 技能核对安装、配置和截图请求入口，最终差异未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/App/Localizable.xcstrings`
- `scripts/codex-runtime/`
- `docs/user-docs/`

### 后续事项

- 在 macOS 13/14 的 Apple Silicon 和 Intel 环境实测组件安装、登录和真实截图 OCR。

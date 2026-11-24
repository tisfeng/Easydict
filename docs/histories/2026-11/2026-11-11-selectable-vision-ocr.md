## 2026-11-11 | 任务：接入可选视觉 OCR 服务

**Links:** [PR #1391 设计讨论](https://github.com/tisfeng/Easydict/pull/1391#issuecomment-6773145695) · [执行计划](../../exec-plans/completed/2026-11/2026-11-11-selectable-vision-ocr.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

在当前 PR 分支实现可选 OCR，默认 Apple，首版接入 Codex。沿用服务配置、截图入口和翻译窗口。验证后创建本地提交。

### 变更

- 在高级设置增加 OCR 服务选择器，按服务实例保存选择。
- Codex 本机 CLI 复用服务的模型和思考强度，仅转写图片，发送前检查图像能力。
- 移除独立公式模式及结果卡的截图专用配置。沿用原有输入框、翻译服务和截图入口，保留已有 OCR 与隐私修复。
- 编辑、清空和重新识别会使旧 OCR 请求失效。

### 设计意图

OCR 和翻译分别使用各自的服务。Apple OCR 保持默认。带原图预览的截图 OCR 继续使用 Apple 引擎。内置托管目录仅声明文本能力，本次 Codex OCR 使用本机 CLI。

### 验证

- Xcode 27.2 Debug 构建及最终 51 项 Codex、Markdown 和 Apple OCR 二维码测试通过。
- 较早两次英文 Vision 精确文本断言失败，最终无调试实例运行时复跑通过。
- 在实际 Debug 构建验证服务切换和截图入口。Codex 将合成法语公式转写为可编辑 LaTeX，DeepL 翻译成功。切回 Apple OCR 后，相同入口也正常识别和翻译。
- 本地化 JSON 和 `git diff --check` 通过。代码审查复核了默认路由、失效回调、模型校验和翻译入口。

### 受影响文件

- `Easydict/Swift/Model/DetectManager.swift`
- `Easydict/Swift/Service/CodexCLI/`
- `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTab.swift`
- 查询窗口接线、字符串目录和中英文使用指南。

### 后续事项

- 本轮界面验证覆盖截图翻译。剪贴板图片翻译和静默截图 OCR 复用同一识别路由。

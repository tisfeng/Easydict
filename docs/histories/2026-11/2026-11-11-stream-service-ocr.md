## 2026-11-11 | 任务：统一视觉 OCR 服务

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [执行计划](../../exec-plans/completed/2026-11/2026-11-11-stream-service-ocr.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

由服务声明 OCR 能力，默认 Apple OCR。首批大模型服务接入 Codex 和 OpenAI，保留现有截图和翻译流程，并新增公式图片测试。

### 变更

- OCR 设置根据已添加服务的能力生成候选，Codex 登录方式不再影响候选列表。
- StreamService 共用图片编码、Markdown 和 LaTeX 转写提示及结果转换。Codex 和 OpenAI 使用各自的模型及连接设置。
- 新版托管 Codex 接收直接附加的图片，仍禁用本地图片查看工具。macOS 13/14 的旧版托管运行时继续使用纯文本配置。
- 在 EasydictTests 增加合成公式图及四项验证。

### 验证

- Debug 构建与 55 项测试通过。Apple OCR 使用实际图片，OpenAI 测试使用模拟响应。
- Codex 本机 CLI 和 ChatGPT 登录分别返回了合成图中的公式和编号。七项托管隔离探针通过。
- OpenAI 当前配置的端点两次返回 HTTP 503。已有 Xcode 调试实例持续运行，本次构建的设置选择器界面实测受阻。
- 复核了候选列表、服务配置、请求取消、兼容运行时和错误路径。静态差异及 JSON 校验通过。

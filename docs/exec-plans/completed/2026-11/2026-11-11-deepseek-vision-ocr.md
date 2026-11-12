# 接入 DeepSeek 视觉 OCR

- 状态：completed
- 创建日期：2026-11-11
- 负责人：Unknown
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1391

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B52)`

## 背景

当前 DeepSeek 服务仅发送文字，现有 OCR 选择无法使用官方已提供的 Flash 图片输入接口。

## 目标与范围

- 目标结果：现有 OCR 选择提供 DeepSeek，并返回可由共享 Markdown/LaTeX 预览显示的原文。
- 允许修改路径：DeepSeek 服务、OCR 文案、相关测试与本任务记录。
- 同任务 history：`docs/histories/2026-11/2026-11-11-deepseek-vision-ocr.md`
- 用户限制：仅在本机接入；保留现有服务配置和本地自动保存关闭状态。
- 非目标：合并识图与翻译请求、修改其他翻译服务、推送远程 PR。
- 验收标准：支持 Flash 图片输入；非视觉模型给出明确提示；配置与请求沿用现有服务；安装后可在 OCR 中选择。

## 工作计划

1. 核对官方图片格式与当前服务配置，补充最小图片请求和模型限制。
2. 更新本地化，按授权维护现有测试并运行相关验证。
3. 审查改动、更新本机应用并检查 OCR 列表和图片识别。
4. 记录结果并创建本地提交。

## 风险与决策

- 图片沿用现有内存 Data URL 路径；密钥使用服务配置，文档和日志仅记录脱敏结果。
- 官方 Vision 与模型列表文档确认 Flash 图片输入；V4 Pro 的输入为文字。
- 用户已明确允许更新旧断言并补充图片请求、非视觉模型提示的回归测试。
- 更新应用签名可能要求 macOS 重新确认录屏权限，按实际系统提示处理。

## 进度

- [x] 已核对官方 Vision 和模型列表文档。
- [x] 实现 DeepSeek OCR。
- [x] 完成验证、审查与本机安装。

## 验证

- 初始 HEAD：`b22bec79784bf2750760f0b83d18011c25d28472`，工作区与索引干净。
- 官方接口参考：https://api-docs.deepseek.com/guides/vision/
- 官方模型能力参考：https://api-docs.deepseek.com/api/list-models/

- `build-for-testing`：成功，SwiftFormat 与 SwiftLint 按项目配置运行。
- 默认计划的相关回归：10 个套件、139 项测试通过。
- 单独的 `DeepSeekOCR` 计划：真实 Flash 识图通过，保留测试编号、分式、上下标和公式定界符。
- 本机界面：已观察高级设置的 OCR 服务为“DeepSeek 翻译”，文案包含 DeepSeek；截图已通过界面工具检查。
- 代码审查：已核对请求编码、模型限制、取消、认证、文字翻译兼容性和本地化，未发现有效阻塞项。
- 本机安装：唯一测试版已更新，保留服务配置，本地自动保存维持关闭。

## 完成条件

- 代码、文案与获准测试完成，必要验证通过并完成本机应用交付。
- 验证受阻部分如实记录，history 与归档计划互相链接。

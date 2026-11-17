# 可选视觉 OCR

- 状态：completed
- 创建日期：2026-11-11
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1391

## 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

## 背景

截图翻译应能使用视觉 OCR，同时复用现有翻译流程和服务配置。

## 目标与范围

- 目标结果：Apple OCR 默认，Codex 可选，复用服务配置。
- 允许修改路径：OCR 路由、Codex 图像请求、现有设置与截图相关界面、文档。
- 同任务 history：`docs/histories/2026-11/2026-11-11-selectable-vision-ocr.md`
- 用户限制：当前分支，保留已有改动，本地提交，不 push。
- 非目标：新增窗口入口、独立翻译模式或设置体系。
- 验收标准：保留默认路径，验证 Codex 转写与识别失效处理。

## 工作计划

1. 移除独立公式模式的接线，保留 OCR 和隐私修复。
2. 接入服务选择、Codex 转写和请求取消。
3. 验证、审查、归档并本地提交。

## 风险与决策

- 设置选中服务实例，远程失败不自动转发给其他服务。
- 内置托管目录仅声明文本能力，首版使用本机 Codex CLI，在发图前验证所选模型。

## 进度

- [x] 接入、验证和代码审查。

## 验证

- Xcode 27.2 Debug 构建通过，最终四个套件共 51 项测试通过。
- 实际应用中切换 Apple OCR 和 Codex，使用同一张合成图走截图翻译。Codex 保留 LaTeX，两个路径均由 DeepL 翻译。
- 较早两次英文 Vision 精确文本断言失败，最终独立复跑通过。
- 本地化 JSON、七种界面语言和 Git 补丁检查通过。

## 完成条件

- 验证和审查完成，归档记录并提交。

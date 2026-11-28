# 修复联合 OCR 分发及失败卡片刷新

- 状态：completed
- 创建日期：2026-11-22
- 负责人：Unknown
- 关联 Issue/PR：[PR #1403](https://github.com/tisfeng/Easydict/pull/1403)

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

联合 OCR 的后续审查指出：完整原文分发会与先前的片段翻译竞争；输入改变后，失败的联合 OCR 卡片无法通过重新展开刷新。

## 目标与范围

- 目标结果：提前发出的片段请求不能写入完整结果；失败卡片只在输入相同时保留错误。
- 允许修改路径：`DetectManager.swift`、`OCRTranslationRequest.swift`、`EZBaseQueryViewController.m` 和本任务计划及历史。
- 同任务 history：`docs/histories/2026-11/2026-11-22-fix-ocr-follow-up.md`
- 用户限制：两条问题分别提交、逐个验证。
- 非目标：推送或修改 GitHub 评论。
- 验收标准：联合图片请求持续运行；其他服务不会因展开而收到未识别完的原文；不同输入展开时使用现有刷新路径。

## 工作计划

1. 阻止展开卡片发出片段请求，独立验证并提交。
2. 修复失败卡片展开，独立验证并提交。

## 风险与决策

- 在发起查询前检查原文状态，避免依赖具体服务如何取消网络回调；保留展开选择和完整原文分发。
- 保留相同输入的失败卡片，让用户仍可选择重新识别图片。

## 进度

- [x] 完成两条修复，分别运行定向测试和审查。

## 验证

- 分发：`LocalEnvironment` 的 `screenshotFansOutWithoutRetranslatingDeepSeek()` 通过，确认完整原文分发而联合服务没有重复查询。审查了展开入口和语言检测后的回调，均会在原文未完成时阻止片段查询。
- 失败卡片：`Default` 的 `ReverseTranslationTests` 全部 8 项通过，包括原生卡片折叠及展开测试。代码审查确认仅输入有变化时重走刷新路径，相同输入保留原错误和重试入口。
- 现有测试没有覆盖原文流式期间点击卡片或 OCR 失败后编辑再展开的完整前台路径；未取得这两条路径的实测截图。

## 完成条件

- 两条变更分别验证审查，并分别创建本地提交。

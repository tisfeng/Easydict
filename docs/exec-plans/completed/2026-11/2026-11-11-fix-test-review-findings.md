# 修复 PR #1391 测试审查问题

- 状态：completed
- 创建日期：2026-11-11
- 负责人：Unknown
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1391

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

默认计划中的 OCR 测试受语言偏好异步初始化影响。服务验证可能接受空结果，MDict 缺少配置时也显示通过。

## 目标与范围

- 目标结果：稳定初始化 OCR 测试模型，断言真实服务输出，准确报告 MDict 跳过。
- 允许修改路径：OCRStreamingTests、ServiceTests、MDictReaderTests 及任务文档。
- 同任务 history：`docs/histories/2026-11/2026-11-11-fix-test-review-findings.md`
- 用户限制：逐项修复上一轮审查中的三项问题。
- 非目标：应用生产代码和 GitHub 远程操作。
- 验收标准：OCR 在 Auto 偏好下通过，服务验证要求非空内容，MDict 缺配置报告跳过且配置有效时运行断言。

## 工作计划

1. 等待 OCR 模型初始偏好到达，再设定测试语言。
2. 检查服务返回的译文或词典释义。
3. 用 Swift Testing trait 表达 MDict 的本机路径条件。
4. 实跑验证、复核差异并提交。

## 风险与决策

- 复用主队列的偏好派发顺序，避免为了测试改动生产代码或全局语言配置。
- 保留词典 HTML 和结构化释义作为有效输出。

## 进度

- [x] 完成修复、验证和审查。

## 验证

- 默认计划中的 OCR 流式、免配置服务和 MDict 单元测试共 32 项通过。
- 源语言和目标语言均为 Auto，OCR 流式套件重复三轮通过。
- 本机环境计划单独运行外部 MDict 测试，缺路径为 1 项跳过，提供临时 MDX/MDD 文件为 1 项通过。
- `git diff --check` 通过。

## 完成条件

- 逐项核对验收结果，记录验证范围后归档。

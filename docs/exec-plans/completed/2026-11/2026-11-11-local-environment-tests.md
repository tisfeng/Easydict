# 统一 Xcode 测试计划

- 状态：completed
- 创建日期：2026-11-11
- 负责人：Unknown
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1391

## 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

Codex 和 DeepSeek 的真实测试各有一份计划，默认计划维护手写排除项。

## 目标与范围

- 目标结果：共享 Default 和 LocalEnvironment 两份测试计划。
- 允许修改路径：测试用例、计划、共享 Scheme、项目引用及对应说明。
- 同任务 history：`docs/histories/2026-11/2026-11-11-local-environment-tests.md`
- 用户限制：默认测试排除依赖本机配置的用例，支持命令行和 Xcode 单独运行。
- 非目标：更改应用运行时行为。
- 验收标准：Xcode 默认和专用计划按标签分组，两个单测入口能运行相同用例。

## 工作计划

1. 清点真实环境用例，迁移需要标签的 XCTest 用例。
2. 更新两份计划、Scheme、文件引用及运行说明。
3. 验证两个计划的实际筛选、命令行和 Xcode 单测入口，审查后提交。

## 风险与决策

- 保留既有测试断言及 actor 约束。日常测试仍允许无需个人配置的网络服务验证。
- 以实际测试结果核对标签筛选。Xcode 枚举结果仍可列出尚未按标签筛选的测试。

## 进度

- [x] 完成修改、验证及审查。

## 验证

- `xcodebuild -showTestPlans` 只列出 Default 和 LocalEnvironment。
- 默认计划同时指定 9 个本机环境用例和 3 个对照用例，测试报告只有 3 个对照用例并全部通过。
- 命令行和 Xcode 编辑器分别运行单个 Codex OCR 用例，均通过，测试报告各记录 1 项。
- LocalEnvironment 对照运行选择 Apple OCR 和外部 MDict 用例，只执行 MDict 用例。

## 完成条件

- 验证两份计划及单测入口后归档。

# 精简当前内置模型并保留免费选项

- 状态：completed
- 创建日期：2026-10-24
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1371

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户要求按已修正方案只维护当前模型系列，智谱例外保留正在使用的两个免费模型和默认项。

## 目标与范围

- 目标结果：移除旧 OpenAI、Claude、Groq、智谱模型，增加 GLM-5.3-Flash；免费模型与默认项不变。
- 允许修改路径：相关服务的模型列表、BuiltInAI 引用、必要现有测试、本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-24-refresh-current-models.md`
- 用户限制：测试和 review 后本地提交，不 push；保留两个指定智谱免费模型。
- 非目标：修改自定义模型、持久化配置、温度判断、代理后端或工程配置；新增扩写测试。
- 验收标准：列表符合方案、无悬空引用、相关测试与 review 通过，已有工程改动不进入提交。

## 工作计划

1. 保存初始状态，收敛模型枚举与内置 AI 引用。
2. 执行现有相关测试和静态检查，使用 review 技能审查本次差异。
3. 更新 history、归档计划，用 git-commit 技能创建本地提交。

## 风险与决策

- 初始工程文件有用户改动，保留其原始字节，不纳入本次提交。
- GLM-5.3-Flash 为付费选项，不放入内置免费服务；当前默认项保持 GLM-4-Flash-250414。
- 按用户要求保留 GLM-4.5-Flash ID；官方已注明该 ID 自动路由至 GLM-4.7-Flash。
- Groq 两个 Llama 模型已对免费和开发者层关停，同时删除内置 AI 中相关引用，不推测代理后端支持替代模型。
- 已有持久化列表保持不变，默认列表收敛不强制迁移用户配置。

## 进度

- [x] 实现与静态检查。
- [x] 测试和 review。
- [x] 记录与归档；随任务本地提交。

## 验证

- 独立 Agent DerivedData 的 `xcodebuild test` 通过，两个现有 suite 共 7 个测试。
- 测试临时设置 `EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved`，不覆盖常规发布打包。
- `git diff --check`、模型列表和默认项静态核对通过；移除项无遗留枚举引用。
- review 本次六个源码/测试文件：无范围内 finding；直接修改枚举与引用已足够，无需增加能力表或迁移层。
- review 前后内容摘要一致；工程文件和锁文件与初始字节一致。
- 未发起在线 API 翻译，不把本地测试视为在线可用性或延迟验证。

## 完成条件

- 范围内实现、验证和 review 完成，保留用户初始改动并创建本地提交，不 push。

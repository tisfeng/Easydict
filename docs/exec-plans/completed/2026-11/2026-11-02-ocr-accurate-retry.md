# 修复 OCR 降级语言匹配并移除启动预热

- 状态：completed
- 创建日期：2026-11-02
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1382

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

## 背景

PR #1382 在 accurate 超时或 API 错误后永久禁用该进程的 accurate 路径；fast 语言过滤还会因
地区标识差异误删支持的语言。用户要求每次 OCR 先尝试 accurate，失败后仅对当次请求降级一次
fast，修复语言匹配并完整移除 OCR warm-up。用户明确授权记录既有 golden 失败，在确认没有
新增回归和完成 Review 后创建本地提交，不 push。

## 目标与范围

- 目标结果：逐次 accurate 优先、有界 fast 降级、等价语言匹配；源码与工程中移除全部 OCR 预热。
- 允许修改路径：`Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`、
  `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine+WarmUp.swift`、
  `Easydict/App/EasydictApp.swift`、`Easydict.xcodeproj/project.pbxproj`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-11/2026-11-02-ocr-accurate-retry.md`
- 用户限制：不新增或扩写测试；不 push；记录已存在的 golden 失败后按明确授权提交。
- 非目标：修改 golden 文本、扩充 fast 模型语言能力、改变 entitlement 或发布。
- 验收标准：accurate 真正退出后释放执行槽；取消不触发 fast；每次最多一次 fast 请求；
  支持语言按等价标识匹配，保留偏好顺序与 Vision 支持值；无预热源码、调用或工程引用；
  所选同配置回归组没有新增失败或既有失败输出变化。

## 工作计划

1. 记录初始源码和测试基线，恢复逐次 accurate 优先并保留底层工作并发限制。
2. 以已实现 accurate 恢复的未提交状态为本轮基线，在同一 Development 签名配置下运行相关测试。
3. 修复 fast 语言匹配，删除预热，迁移 accurate 协调状态并清理工程引用。
4. 重跑相同测试、构建和静态检查；完成 Review，更新 history、归档计划并创建本地提交。

## 风险与决策

- Vision 可能忽略取消，执行槽必须由底层 operation 的退出释放；等待槽位计入 10 秒上限。
- fast 使用 `Locale.Language.isEquivalent(to:)` 匹配，避免自建语言标识规范化规则；
  返回 Vision 的受支持值，指定语言的可用性也使用相同等价关系判断。
- fast 的语言模型能力不因标识匹配而增加；现有 golden 失败保留记录，不改测试以消除失败。
- 完整移除旧系统预热会让首次识别承担初始化成本，旧系统 legacy OCR 主流程保持原实现。
- 使用现有引擎的私有状态和短临界区协调底层请求，不为本次修改引入通用并发框架。

## 进度

- [x] 记录基线并实现 accurate 重试策略。
- [x] 修复 fast 匹配并删除全部预热调用、实现和四处工程引用。
- [x] 完成同配置回归比较、构建与静态检查。
- [x] 使用 review 审查完整交付差异，无未解决的新增有效 finding。
- [x] 更新 history 并归档计划，按用户明确授权交付本地提交。

## 验证

- 初始 HEAD：`5489191e9e6c238ccd890d23a68885ae18c97bd1`。首次实现前工作区干净；
  本轮开始时仅有上轮本任务未提交的 accurate 修复及同任务文档，索引为空。
- 相同 workspace、scheme、arm64 目标、Development 签名和独立 DerivedData 下，语言匹配与
  预热移除前后均执行 `TaskTimeoutTests`、`OCRQRCodeTests`、`OCRImageTests/test()`、
  `OCRImageTests/testAutoLanguageOCR()`、`OCRImageTests/testEnglishOCR()`。
- 两轮均为 12 个测试中 9 个通过、3 个 golden 测试失败；逐条比较 21 条失败消息，实际输出、
  预期值和失败样例完全相同，无新增失败。各样例及日文文本记录在同任务 history。
- 相同配置的签名 Debug `xcodebuild build`：退出码 0。未将测试退出码 65 表述为测试全部通过。
- Swift parser、SwiftFormat lint、`plutil -lint` 与 `git diff --check`：通过。
- Foundation/Vision API 核对：同一偏好列表严格匹配为 0 项，等价匹配按顺序保留法、英、德、
  西、葡、意六种语言；英语明确匹配，日文仍不受 fast 支持。这是 API 探查，不是新增测试。
- 现行源码、测试和 Xcode 工程无 warm-up 残留；旧文件的 build file、file reference、group
  和 Sources 引用全部删除。用户原有应用实例保留，测试宿主已退出。
- review 覆盖完整任务 diff、取消/超时/晚完成释放、语言配置与工程边界，未发现新增有效 finding。
  未新增故障注入测试，生命周期的边界判断仍包含静态审查证据。

## 完成条件

- 范围内实现和工程清理完成；构建、静态检查以及所选回归对比通过。
- 已知 golden 失败准确记录并按用户明确授权接受；不扩大为全量测试或所有系统版本通过。
- Review 无未解决的任务新增有效 finding。
- history 已记录并关联归档计划；本地提交按技能校验，禁止 push。

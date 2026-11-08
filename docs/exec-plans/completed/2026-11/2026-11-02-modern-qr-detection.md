# 迁移现代 Vision 二维码检测 API

- 状态：completed
- 创建日期：2026-11-02
- 负责人：Codex
- 关联 Issue/PR：None

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

## 背景

原有二维码检测在全部系统使用 `VNDetectBarcodesRequest`，通过 GCD 与 continuation 将同步
Vision 工作桥接为异步。用户采纳 macOS 15+ 使用 `DetectBarcodesRequest` 的方案，旧系统
保留原实现，并要求对比现有 golden 失败、完成 Review 后创建本地提交，不 push。

## 目标与范围

- 目标结果：macOS 15+ 使用原生 async API；macOS 13–14 保留同步 Vision 后台桥接，
  共用 payload 过滤/去重和错误策略，取消继续向上传播。
- 允许修改路径：`Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`、
  本计划及同任务 history。
- 同任务 history：`docs/histories/2026-11/2026-11-02-modern-qr-detection.md`
- 用户限制：运行现有测试，不新增或扩写测试；不 push；记录已知 golden 失败后按明确授权提交。
- 非目标：改变文字 OCR 路由、识别模型、超时预算、条码种类或 golden 预期。
- 验收标准：新系统直接 await 检测；旧系统保留 utility QoS 桥接；空 payload 被过滤，
  去重保留首次出现的原始内容；普通检测错误继续文字 OCR，取消不被吞掉；所选回归无新增失败。

## 工作计划

1. 记录干净初始快照，在同配置下运行现有测试作为基线。
2. 分离新旧二维码 helper，统一处理结果和错误。
3. 重跑相同测试与构建、格式和差异检查，逐项比较已知失败。
4. 使用 review 审查任务 diff，完成 history、归档计划并创建本地提交。

## 风险与决策

- 依据 Apple 文档与本机 SDK 的 macOS 15 availability 分流，不沿用文字 OCR 的 macOS 26 门槛。
- 新旧 API 的 `payloadString` / `payloadStringValue` 均先转换为原始字符串，再统一规范化比较。
- 新 API 的 `VisionError.requestCancelled` 转为取消；普通错误统一记录并返回空数组。
- 旧 helper 使用 throwing continuation 将同步错误交给统一入口处理，保留原 API、utility QoS、
  同步执行与对外 best-effort 行为；没有 callback 与同步完成竞争导致的重复 resume 路径。
- 原生异步不构成立即取消或有界耗时保证，本次不扩展二维码超时策略。
- 三个局部 helper 足以隔离兼容路径，不引入通用请求适配层或额外任务调度。
- 用户要求分支分工：旧 `fix/vision-ocr-fallback` 回主工作区，当前 worktree 新建
  `refactor/modern-qr-detection`，从同一 `0f05fb134` 起步；不改写旧分支历史。

## 进度

- [x] 核对初始状态并完成用户要求的分支调整。
- [x] 完成同配置基线与实现。
- [x] 完成验证、回归比较和 Review。
- [x] 更新 history、归档计划，按明确授权交付本地提交。

## 验证

- 初始 HEAD：`0f05fb13466c9793897d102a2f0d26dec21396e9`，工作区和索引均干净。
- 当前 worktree 使用独立 DerivedData；因没有本地签名配置，两轮命令均沿用项目开发团队与
  Apple Development 签名，保持原 bundle ID，与用户原有应用实例隔离构建产物。
- 同配置前后各执行相同的 12 个现有测试：`TaskTimeoutTests`、`OCRQRCodeTests`、
  `OCRImageTests/test()`、`testAutoLanguageOCR()`、`testEnglishOCR()`。
- 两轮均为 9 个通过、3 个 golden 测试失败；四个二维码测试均通过。
  逐条比较 21 条失败消息，失败样例、实际输出和 golden 预期完全一致，无新增失败。
- 修改后 Development 签名 Debug `xcodebuild build` 退出码 0；测试进程退出码为 65，
  没有将已知 golden 失败计为通过。详细失败范围记录于同任务 history。
- Swift 5 API 类型检查以 macOS 13 为最低目标通过；工程最低部署版本仍为 macOS 13。
- Swift parser、SwiftFormat lint、`git diff --check` 通过。
- review 覆盖完整任务 diff、availability、普通错误和两类取消传播、payload 原样返回与去重、
  continuation 单次恢复和现有调用链，未发现新增有效 finding。
- 未新增测试；取消/错误边界仍包含静态审查证据，未把未运行的故障注入验证描述为通过。
- 实际运行系统为 macOS 27.0.1；macOS 13–15 仍需对应环境运行验收。
- 主工作区保持 `fix/vision-ocr-fallback` 与原提交，用户原有应用实例保留，测试宿主已退出。

## 完成条件

- 需求实现并通过构建与静态检查。
- 所选现有测试与基线比较无新增回归，既有 golden 差异明确记录。
- Review 无未解决的新增有效 finding。
- history 与归档计划齐全；本地提交按技能校验，不 push。

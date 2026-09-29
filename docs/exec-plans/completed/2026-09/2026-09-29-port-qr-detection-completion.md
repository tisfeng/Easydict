# 移植二维码检测 QoS 与完成时机修复

- 状态：completed
- 创建日期：2026-09-29
- 完成日期：2026-09-29
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

Easydict 的二维码检测仍以 utility QoS 执行，并在 Vision completion handler 中恢复 continuation。
SDK 明确指出回调早于同步 `perform` 返回，后续文字 OCR 因而可能提前开始。
用户授权移植 Scoco 提交 `630cb7536f9f59df61f9ab692e7d937c39081768` 中的局部修复。
历史上的同类诊断见 [此前记录](../../../histories/2026-09/2026-09-26-fix-qr-vision-qos.md)。

## 目标与范围

- 目标结果：用户触发的 QR 检测使用 userInitiated 后台队列，同步请求返回后统一交付结果。
- 允许修改路径：`Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift`、本计划与同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-29-port-qr-detection-completion.md`
- 用户限制：实际运行测试由用户完成；本地提交，不 push。
- 非目标：改动文字 OCR、预热、二维码结果规则或新增测试。
- 验收标准：静态检查与编译验证通过，完成 review；实际识别与警告复验交还用户。

## 工作计划

1. 局部改写 `detectQRCodePayloads(on:)`，保留旧版文字 OCR 使用的通用 ContinuationGate。
2. 完成单文件检查和隔离构建，审查成功、空结果与异常路径。
3. 记录验证边界，归档计划并创建本地提交。

## 风险与决策

- 基线 `f50244578ec67f2131b4770a88371b8d19e74834`，首次写入前工作树与索引干净。
- Swift language mode 为 5.0，无显式严格并发或默认 actor isolation 设置；不做并发语言迁移。
- 请求、handler 和读取结果留在同一 GCD 工作项内，避免在 cooperative executor 中同步执行 Vision。
- QR 路径只恢复一次 continuation；通用 gate 仍用于旧版文字 OCR，不删除。
- 不把 QoS 对齐或静态验证视为 Vision 内部警告消失的证明。

## 进度

- [x] 移植局部修复。
- [x] 完成静态检查、编译与 review。
- [x] 更新 history，随本地提交归档。

## 验证

- `git diff --check`、单文件 SwiftFormat lint、Swift frontend parse 均通过。
- SwiftLint 使用 `--use-script-input-files --config .swiftlint.yml --strict --no-cache`：0 violations。
- 隔离 DerivedData 的 arm64 Debug 构建通过；使用 `EASYDICT_RELEASE_PACKAGING=YES` 跳过构建阶段的整仓 Format/Lint，以单文件检查覆盖本次变更。完整命令见同任务 history。
- Review 对照基线核查完整源码差异与调用链：未发现有效 finding。成功、空结果和异常路径只恢复一次 continuation，旧版文字 OCR 的通用 gate 完整保留。
- 实现方式判断：在原私有函数中收敛同步请求生命周期已经足够，无需新增 detector 类型或调度抽象。
- 源码 SHA-256：`f1ac7c33ebc8981d001303568ea555ea39d497667b05d8bf980aca6441f7b620`，编译和审查后复验一致。
- 按用户要求未运行 OCR 用例或实际 Xcode Run；识别行为和原始警告由用户复测。

## 完成条件

- 修改仅覆盖允许路径，必要静态检查和编译通过。
- review 无未处理的有效 finding。
- history 记录实际运行未验证边界，计划与本地提交同步交付。

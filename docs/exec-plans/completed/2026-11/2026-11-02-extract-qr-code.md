# 抽取独立 QRCode 类

- 状态：completed
- 创建日期：2026-11-02
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B48)`

## 背景

参考 Scoco 的 QRCode 职责拆分，将 Easydict 中嵌入 AppleOCREngine 的二维码逻辑独立维护。

## 目标与范围

- 目标结果：独立 QRCode 类负责检测、去重、QR-only 结果构造及追加内容。
- 允许修改路径：AppleOCREngine.swift、同目录 QRCode.swift、project.pbxproj 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-11/2026-11-02-extract-qr-code.md`
- 用户限制：参考 Scoco；不修改 Scoco，不新增或扩写测试。
- 非目标：同步 Scoco 截图 UI、几何观测数据或改变二维码识别与合并行为。
- 验收标准：保留现有 modern/legacy、取消及错误语义；现有 OCRQRCodeTests 通过，工程正确引用新文件。

## 工作计划

1. 对照两项目实现，抽取 QRCode 类及其调用点，同步工程引用。
2. 运行现有 QRCode 测试及静态检查，按 review 技能审查最终变更。
3. 记录结果，归档计划，创建本地提交。

## 风险与决策

- Scoco 使用 enum/static；Easydict 当前实例成员规则优先，因此采用 final class 和 engine 持有实例。
- 保留 Easydict 的 mergedText 重建逻辑，避免将职责抽取扩大为行为修改。
- textProcessor.reset() 仍由 AppleOCREngine 在 QR-only fallback 前调用。
- 初始 HEAD：`3fce1a81056bf220583a85ced33800d889693c42`；dev 分支，初始工作树和索引干净。

## 进度

- [x] 明确职责与现有行为。
- [x] 完成抽取与工程接入。
- [x] 完成验证与审查；文档归档后按仓库规则本地提交。

## 验证

- Debug 定向 `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -derivedDataPath "$agent_dd" -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:EasydictTests/OCRQRCodeTests`：退出码 0；xcresult 为 Passed，4 项通过、0 失败。
- 两个生产 Swift 文件的 SwiftFormat lint：0 文件需格式化。
- `plutil -lint Easydict.xcodeproj/project.pbxproj` 与 `git diff --check`：通过。
- review：针对初始 HEAD 和三个生产/工程文件的最终内容，检查检测与取消传播、去重、QR-only reset、两轮 OCR 追加位置及 Sources 引用；无有效 finding。实例封装足以满足任务，无需加入几何数据或截图 UI。
- 未执行 Release、UI 验证及 macOS 13/14 legacy 路径运行验证；legacy 实现仅迁移，未改变逻辑。
- 运行测试前确认无已运行 Easydict 实例；OCR 测试写入共享截图文件，因此关闭测试并行。

## 完成条件

- 必要验证通过、审查无有效 finding，history 已更新且计划归档。

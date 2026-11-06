# 修复划词浮层的光标与事件生命周期

- 状态：completed（候选修复；完整应用与长期运行验证待补充）
- 创建日期：2026-10-06
- 负责人：FrancisCheng777
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/issues/1177

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode Unknown (not installed; Command Line Tools available)`

## 背景

用户报告 Easydict 长时间运行后箭头与文本光标反复切换，退出应用后恢复。
当前临时措施是关闭自动划词图标。需要调查实际的 AppKit 事件与浮层生命周期，
提交有证据支持的修复，而不将相关 issue 的症状直接作为具体根因证明。

## 目标与范围

- 目标结果：消除经调查确认的光标、绘制或划词事件生命周期缺陷。
- 允许修改路径：划词事件、浮层和直接相关的 AppKit 视图，以及本任务文档。
- 同任务 history：`docs/histories/2026-10/2026-10-06-selection-cursor-lifecycle.md`
- 用户限制：保留现有应用配置和自定义 PRO 功能；用户已授权向官方提交 PR。
- 非目标：翻译服务、词库和无关的 UI 重构。
- 验收标准：对已定位行为提供可复验的证据；完成可用验证和代码审查；如无法整包构建，明确披露。

## 工作计划

1. 检查当前 dev、issue 日志及相关未合并 PR，定位最小缺陷。
2. 通过最小 AppKit 诊断实验核对行为，实施局部修复。
3. 运行可用检查，尝试项目要求的 Xcode 验证并记录环境限制。
4. 使用仓库 review 技能审查差异，记录结果并提交 PR。

## 风险与决策

- 长时间运行的光标闪烁需要现场验证；局部诊断不能替代该验收。
- 避免复制 PR #1325 的异步取词修复或夹带用户自定义词库修改。
- 当前只有 Command Line Tools，完整 Xcode 构建和测试可能受阻。
- 未获新增测试授权，不增加仓库测试用例；使用现有检查和临时诊断实验。

## 进度

- [x] 建立独立 dev checkout，检查 issue 与现有 PR。
- [x] 移除 cursorUpdate 监听，补全关闭、取消和异步结果的清理。
- [x] 完成 AppKit 对照实验、现有测试、语法检查和代码审查；记录整包验证限制。
- [x] 更新 history；以候选修复交付 Draft PR，保留长期验证要求。

## 验证

- `xcodebuild -version`：失败，当前 developer directory 为 Command Line Tools，未安装完整 Xcode。
- 使用生产 `EventMonitorEngine.swift` 的临时 AppKit 实验，分别采用修改前后的事件 mask 和模拟默认关闭回调，注入一次 cursorUpdate：修改前回调 1 次并关闭浮层；修改后回调 0 次，浮层保持可见。实验不证明数小时后的全局闪烁已经解决。
- 现有 `ThrottleGateTests` 的 5 个用例通过独立 Swift Testing runner 全部通过，未修改测试文件；仅验证现有节流器的行为。
- 修改后的 `EventMonitor.swift` 通过 Swift parser；相关 Engine、EventTap、VisibilityController 和 ThrottleGate 通过独立 typecheck。这不等同于完整 EventMonitor 的类型检查或应用构建。
- CLT 存在重复 SwiftBridging module map；以上命令通过临时 VFS overlay 避开冲突，不修改系统工具链。SwiftPM runner 另遇 PackageDescription 链接错误，已改用直接编译现有测试的 runner。
- `xcodebuild test` 因无完整 Xcode 无法执行。
- `git diff --check` 通过；review 检查点击激活、Cmd+C 忽略规则、延迟任务和异步回调。保留原查询动作判断的捕获时机，避免后台回调到主线程期间动作类型变化造成额外语义变更。
- 审查后的源码 SHA-256：`423bfda8db220fe1471bdf7239c16308f499c530e312c1e624c935d845eb5ec4`。未发现有证据的阻塞代码缺陷；完整构建、完整交互和长时间运行仍未验证。

## 完成条件

- 所有代码变更具备具体证据与明确范围。
- 记录可用验证、审查结果和未验证的用户症状。
- 创建对应 history，并将计划归档。

# 修复 SwiftUI 状态发布警告

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** Codex
- **Model:** Unknown
- **Environment:** macOS 27.0 / Xcode 27.2 (27B5019j)

## 背景

Easydict 在设置页出现两类运行时警告：`ServiceTab` 在 SwiftUI view update 期间同步发布状态，以及 Defaults/Combine 观察者可能在写入偏好设置的后台线程直接更新 UI 或模型状态。前者来自多选 `List` 的 Binding setter，后者来自若干未切换到主线程的 Defaults publisher。

## 目标与范围

- 目标结果：将 `ServiceTab` 的 selection 状态提交延迟到当前 view update 事务之后，并让受影响的 Defaults publisher 在主线程交付。
- 允许修改路径：`Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTab.swift`、`Easydict/Swift/View/SettingView/Tabs/TabView/FavoritesTab.swift`、`Easydict/Swift/Feature/Configuration/MyConfiguration.swift`、`Easydict/Swift/Service/OpenAI/StreamService.swift`，以及本计划、对应 history。
- 同任务 history：`docs/histories/2026-09/2026-09-27-fix-swiftui-publishing-warnings.md`
- 用户限制：不新增或扩写测试；不 push、不创建 PR。
- 非目标：不重构 ServiceTab selection 模型，不修改 Defaults 库源码，不处理与本次警告无关的 publisher。
- 验收标准：相关状态写入不再同步发生在 SwiftUI view update 内；Defaults 观察回调统一在主线程执行；代码通过独立 DerivedData 构建和本地 Review。

## 工作计划

1. 确认主仓库状态、源码调用链和所有相关 publisher。
2. 修改 ServiceTab selection 的提交时机，并为相关 Defaults publisher 增加主线程交付。
3. 运行静态检查和独立 DerivedData 的 Xcode build。
4. 使用本地 review skill 审查变更，修复有效 finding 后重新验证。
5. 写入 history，归档本计划，并创建本地 Angular-style 提交。

## 风险与决策

- `@MainActor` 只能约束执行线程，不能解决 SwiftUI view update 事务内同步发布，因此 selection setter 使用 `DispatchQueue.main.async` 延迟提交。
- Defaults publisher 的回调线程取决于偏好设置写入线程，直接在 publisher 后接收会把线程契约固定为主线程；已有使用主线程 scheduler 的链路保持不变。
- 连续 selection 更新使用 generation 丢弃过时的排队任务，避免旧选择覆盖新状态。
- 本次不新增测试，使用构建、diff 检查和静态调用点核对验证。

## 进度

- [x] 完成现状调查并确认修改范围。
- [x] 完成源码修改。
- [x] 完成构建和 Review。
- [x] 更新 history、归档计划并准备创建本地提交。

## 验证

- `git diff --check`：通过。
- 独立 DerivedData 的 `xcodebuild build`：通过，两轮构建均成功。
- 本地 review：通过，未发现需要修复的 finding。
- 全套 `xcodebuild test`：环境敏感套件出现失败/超时，未形成整套通过结果，已记录在 history。

## 完成条件

- 计划内源码修改通过构建和 Review，history 已写入，计划已归档，并创建本地提交。

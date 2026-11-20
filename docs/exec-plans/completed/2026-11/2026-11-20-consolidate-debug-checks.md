# 集中 Swift Debug 构建判断

- 状态：completed
- 创建日期：2026-11-20
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

仓库已用 `BuildConfig.isDebug` 暴露构建类型，菜单栏、事件监控和遥测仍分别进行条件编译。
MDict 生产代码通过条件编译提供一个仅由测试调用的压缩方法。

## 目标与范围

- 目标结果：把 Swift 行为分支集中到 `BuildConfig.isDebug`，将 MDict 压缩方法移到测试 target。
- 允许修改路径：`EasydictApp.swift`、`EventMonitor.swift`、`AnalyticsService.swift`、
  `MDictBinary.swift`、`MDictReaderTests.swift` 及本任务 plan 和 history。
- 同任务 history：`docs/histories/2026-11/2026-11-20-consolidate-debug-checks.md`
- 用户限制：按已确认方案执行。
- 非目标：调整 Objective-C 日志初始化和分类加载、`AGENT_CLI_DEBUG` 或发布配置。
- 验收标准：自有源码的 `DEBUG` 条件编译从 9 处降到 3 处，Debug 和 Release 行为按原条件执行。

## 工作计划

1. 替换三个 Swift 模块的构建判断，移动 MDict 测试方法。
2. 构建 Debug 和 Release，运行现有 MDict 测试并验证菜单栏图标和受影响分支。
3. 审查最终差异，记录结果，归档计划并创建本地提交。

## 风险与决策

- 保留读取 `MyConfiguration.shared` 的顺序，维持配置订阅的初始化时机。
- 事件监控保留函数级 `defer`，Release 跳过计时和日志格式化。
- Objective-C 保留全局变量的静态初始值和分类的编译隔离。

## 进度

- [x] 实现并静态检查。
- [x] 构建和实测。
- [x] 审查并归档。

## 验证

- 原生 arm64 的 Debug 测试构建和 Release 构建通过。现有 `MDictReaderTests` 21 项全部通过。
- 以相同方形图标实测两个产物。Debug 显示蓝色原图，Release 显示白色模板图。
  截图保存在仓库外，验收后恢复原 Debug 实例。
- 二进制检查确认事件耗时日志仅出现在 Debug，压缩 helper 从两个应用产物移除。
  核对 Firebase 和 Sentry 的分支。离线日志未确认 Sentry 实际关闭，未验证远端上报。
- SwiftFormat 和 `git diff --check` 通过。源码扫描剩余 3 处条件编译，最终差异审查无发现。

## 完成条件

- 范围内修改完成，验证和审查结果已记录。

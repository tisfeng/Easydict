# 精简应用路径管理

- 状态：completed
- 创建日期：2026-09-17
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

Easydict 已使用 `AppPathManager` 统一应用本地路径，但现有扩展仍按系统目录组织，
`AppPathManager+ApplicationSupport.swift` 混合了 Codex、日志和缓存职责；目录创建函数单独占用一个
文件，通用迁移类型名称也偏长。菜单栏导出日志目前只覆盖常规应用日志，不能提供完整调试材料。

## 目标与范围

- 目标结果：按业务域组织路径 API，简化核心命名和迁移类型，并让日志查看与完整调试导出各自使用
  正确目录。
- 允许修改路径：`Easydict/Swift/Utility/AppPathManager/`、`Easydict/App/EasydictApp.swift`、
  `Easydict/Swift/View/MenuItemView.swift`、`Easydict.xcodeproj/project.pbxproj`、
  `docs/design-docs/app-path-management.md`、同任务 plan 与 history。
- 同任务 history：`docs/histories/2026-09/2026-09-17-refine-app-path-management.md`
- 用户限制：日志目录只打开常规应用日志；导出日志需要打包全部日志。
- 非目标：不改变磁盘目录布局、迁移算法、Codex 专用迁移边界，不新增或修改测试代码。
- 验收标准：旧路径和数据迁移行为保持不变，工程引用无悬空项，日志菜单行为符合用户要求，构建与
  现有测试通过。

## 工作计划

1. 将目录创建能力合并进核心类型，并将 Application Support 根属性改名为
   `appSupportDirectory`。
2. 将路径扩展重组为 Codex、日志和缓存三个业务域，同时保留全部当前与历史路径。
3. 将 `AppPathMigrationCoordinator` 简化为 `AppPathMigration`，同步启动调用和工程引用。
4. 保持日志目录入口指向 `appLogDirectory`，将日志导出源调整为 `logsDirectory`。
5. 同步 Xcode 工程、长期设计文档和 history，运行静态检查、现有测试及代码审查。

## 风险与决策

- 所有 URL 的路径组件保持不变，避免触发新的数据迁移。
- 通用迁移仍处理日志、音频缓存和 MDict 元数据；只缩短类型名称，不删除或改写安全检查。
- 不增加与 `appSupportDirectory` 等价的 `appRootDirectory` 别名，避免重复入口。
- 完整日志包会包含 Codex CLI 与 Claude Code 调用日志，设计文档必须明确其潜在敏感内容。

## 进度

- [x] 完成源码与工程文件重构。
- [x] 同步设计文档与 history。
- [x] 完成验证与 Review；本地提交在归档后创建。

## 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：通过。
- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：应用和测试 target 编译
  成功；完整测试因既有 OCR、联网服务、AppleScript、计时和进程取消用例失败而未通过。
- 生产代码 Review：未发现 finding。

## 完成条件

- 代码、工程文件和设计文档一致，不存在旧类型名、旧属性名或被删除文件的残留引用。
- 必要验证及 Review 通过，history 已记录落地结果。
- plan 归档到 `docs/exec-plans/completed/2026-09/`，并创建 Angular-style 本地提交。

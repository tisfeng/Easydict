# 设置页标签视图概览

`TabView` 目录保存设置窗口中各个顶层标签页的 SwiftUI 视图。这里的
文件负责把用户偏好、服务开关、快捷键、隐私、关于信息等配置入口组织
成稳定的设置界面，并把具体业务状态交给对应的 view model 或配置存储
对象处理。

## 主要组件

`ServiceTab` 使用嵌入式 `HSplitView` 管理窗口配置、翻译服务列表和服务
配置详情，避免影响设置窗口外层 `TabView`。左栏宽度可在当前窗口会话中
手动拖拽调整，顶部提供窗口配置入口；服务列表使用完整排序，行内通过
`no-key`、`built-in`、`key` 和 `cli` 标签标记 API Key 类型，避免分组
破坏跨类型拖拽排序。

`GeneralTab`、`AdvancedTab`、`ShortcutTab`、`PrivacyTab`、`FavoritesTab`、
`DisabledAppTab` 和 `AboutTab` 分别承载通用设置、高级设置、快捷键、
隐私控制、收藏记录、禁用应用列表和应用信息。它们优先保持表单或列表
结构简单，把复杂状态更新封装在更靠近业务的配置类型中。

## 关键流程

服务页打开时，`ServiceTabViewModel` 按当前窗口类型从 `LocalStorage`
读取服务数组，并默认选中窗口配置。用户切换 Fixed、Mini 或 Main 窗口
类型后，view model 重新回到窗口配置并加载对应窗口的服务配置。

服务列表拖拽排序直接作用于完整服务数组。`onServiceItemMove` 将新的
`serviceTypeWithUniqueIdentifier` 顺序写回 `LocalStorage`，随后发送
服务更新通知并刷新列表，因此 `key`、`no-key`、`built-in` 和 `cli`
服务可以互相穿插排序。

点击左栏窗口配置入口会在右栏显示 `WindowConfigurationView`。点击服务
行会打开右侧服务配置详情；若服务提供 `configurationListItems()`，详情
区用 grouped form 展示该服务的配置，否则显示无配置提示。开关服务时，
普通服务直接写入启用状态，流式服务会先执行校验，Claude Code 会先展示
风险确认弹窗。

## 调试入口

布局异常时，先确认服务页仍使用嵌入式 `HSplitView`，没有把
`NavigationSplitView` 放回设置 `TabView` 内。选择状态异常时，检查
`ServiceTabSelection` 是否正确区分窗口配置和服务 id。服务排序或标签
显示异常时，检查 `ServiceItems` 的 `ForEach` 是否仍然遍历完整
`viewModel.services`，再检查 `ServiceRequirementBadge` 对
`ServiceAPIKeyRequirement` 的映射。

服务启用状态异常时，从 `ServiceItemViewModel.updateServiceStatus` 进入，
确认 `LocalStorage.setService` 和 `postServiceUpdateNotification` 是否被
调用。窗口类型切换异常时，优先检查 `handleWindowTypeChange` 是否触发了
`updateServices()`。

## 2026-11-12 | 任务：首次添加时选择 Codex 接入方式

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-12-initialize-codex-access-mode.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

每个 Codex 服务实例首次添加时异步检测本机 CLI，并持久化选中的接入方式。保留已有设置和迁移规则。

### 变更

- 复用本机 CLI 探测，找到可执行文件时保存本机模式，否则保存内置 ChatGPT 登录。
- 添加流程等待探测结果。界面显示进度，允许取消，确认按钮在添加期间禁用。
- 更新中文使用指南。

### 设计意图

已有模式键跳过探测。异步返回后在主 actor 复查模式键和窗口列表，再按先保存模式、后加入窗口的顺序写入。已有迁移及持久化标识保留。

### 验证

- `xcodebuild test -testPlan Default` 的五个定向套件共 89 项通过。
- review 复核持久化、重新添加和取消路径，差异检查通过。
- 本机可找到 Codex CLI。新 Debug 产物已启动，界面工具连接超时，未完成点击实测或截图。随后重新启动原 Debug 产物。

### 受影响文件

- `Easydict/Swift/Service/Model/Storage/LocalStorage.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTab.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `docs/user-docs/zh/GUIDE.md`

### 后续事项

- 补做本机 CLI 存在及缺失两种环境的界面验收。

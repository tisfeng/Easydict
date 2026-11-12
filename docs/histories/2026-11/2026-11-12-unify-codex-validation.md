## 2026-11-12 | 任务：统一 Codex 验证入口

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-12-unify-codex-validation.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

移除 Codex 内置登录的「测试连接」按钮，统一使用服务设置右下角的「验证」。

### 变更

- 共用底部按钮支持传入验证动作和禁用状态。Codex 内置模式调用原有账户验证，本机模式沿用默认验证。
- 删除账号区旧按钮及对应本地化，更新中文使用指南。

### 设计意图

内置验证继续使用当前服务的模型和推理强度，复用现有账号状态、取消及错误反馈。组件可用、已登录且空闲时允许发起验证。

### 验证

- `xcodebuild test -testPlan Default` 的四个 Codex 套件共 49 项通过。
- JSON 和差异检查通过。review 核对两种接入及共用按钮调用方，未发现需修复的问题。
- 本次 Debug 构建已启动。界面工具连接超时，未完成按钮点击实测或截图。已恢复原 Debug 应用。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/`
- `Easydict/App/Localizable.xcstrings`
- `docs/user-docs/zh/GUIDE.md`

### 后续事项

- 补做两种模式的界面点击验收和截图。

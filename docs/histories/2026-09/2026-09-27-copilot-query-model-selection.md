## 2026-09-27 | 任务：在查询窗口选择 Copilot 模型

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-27-copilot-query-model-selection.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

让 GitHub Copilot 在查询窗口提供模型选择，复用动态目录，并同步设置页及推理等级校验。

### 变更

- 新增主线程隔离的共享模型目录，保存内存快照和加载/错误状态，合并并发请求；界面关闭不取消其他消费者需要的有界查询。
- 查询窗口显示 CLI 默认或当前模型名称，点击后加载最新目录并显示原生选择菜单；区分 CLI 默认与 Auto，勾选当前模型，失败时保留最近目录并提供重试。
- 为 StreamService 增加模型展示、选项、加载及选择接口；静态服务沿用原有模型来源。
- 菜单展示名称与实际模型 ID 分离，携带服务身份防止旧菜单作用于新服务；异步回调核对请求、窗口、视图可见性和服务身份。
- 设置页复用共享目录，打开选择列表时刷新；两处调用统一选择方法，先校验推理等级，再写模型偏好并沿用现有重新查询机制。
- 目录更新使用独立通知刷新模型按钮，不触发翻译；复用全部现有本地化文本。

### 设计意图

模型目录属于账号与 CLI 元数据，不属于某个设置视图。共享元数据与选择动作，保留设置页的 SwiftUI 搜索列表和查询窗口现有 AppKit 菜单边界，不将动态模型写入静态模型配置，也不修改 CLI 翻译协议。

### 验证

- 独立 Agent DerivedData 中的 Debug `xcodebuild build`：成功，仅有 AppIntents metadata extraction 提示。
- SwiftFormat lint、项目固定版本 SwiftLint、`git diff --check`、工程 `plutil -lint`：通过。
- 本次使用的五个本地化 key 均覆盖 en、es、ja、sk、zh-Hans、zh-Hant。
- 生成的 Swift/Objective-C 接口核对：模型展示、可选 ID、异步加载和选择方法正确导出。
- review：覆盖全部任务源码及模型订阅/查询调用链，无剩余 finding；当前方案复用已有菜单和通知边界，范围合适。最终源码与审查快照一致。
- 未新增测试；Xcode Run 正在使用同 bundle ID 的调试宿主，未运行 app-hosted test。新构建的菜单点击、实际翻译和跨窗口同步尚未进行 UI 实测。

### 受影响文件

- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotModelStore.swift`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotService.swift`
- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/GitHubCopilotServiceConfigurationView.swift`
- `Easydict/Swift/Utility/Extensions/Notification/Notification+Name.swift`
- `Easydict/objc/ViewController/View/ResultView/EZResultView.m`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 调试会话允许时，实测冷启动直接选择、CLI 默认/Auto、失败重试、切换后翻译及设置页同步。

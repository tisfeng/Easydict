## 2026-08-26 | 任务：为翻译与润色替换增加在线服务和追加要求

**Links:** `docs/exec-plans/completed/2026-08-25-text-replacement-online-services.md`

### 用户请求

保持翻译并替换和润色并替换的逐 chunk 流式写回，同时允许两个动作分别选择已有
OpenAI 兼容服务实例并配置可空追加要求；补齐单次内置回退、中断提示、安全日志、
本地化、用户指南和自动化测试。

### 变更

- 新增四个全局 Defaults，分别保存两个动作的完整服务 identifier 和追加要求；默认仍为
  BuiltInAI 与 Polishing，空追加要求保持原 Prompt。
- 在服务注册表中声明文本替换能力，从 main、fixed 和 mini 三类窗口配置并集生成候选；
  支持 OpenAI、完整 `CustomOpenAI#uuid`、DeepSeek、Groq、Zhipu、MiniMax、GitHub
  Models 及动作默认内置服务。
- 在高级设置中增加两个独立动作分组，显示服务名、Custom OpenAI 短 UUID 和当前模型，
  并提供可空多行追加要求。
- 新增内部 `TextReplacementPromptContext`。翻译复用原翻译 Prompt，润色复用从
  PolishingService 提取的原 Prompt builder；动作 Prompt 优先于服务页全局 Custom Prompt。
- 将替换执行重构为可测试的流式 consumer/coordinator：非空 chunk 立即写回；零 chunk
  的空流或失败最多回退一次；部分写入或取消后不混合第二个模型，并保留部分结果。
- 删除的服务选择会重置到动作默认值；仍配置的服务即使暂时缺密钥、模型或网络失败也
  保留用户选择。模型为空时不会发出 provider 请求。
- 将动作日志限制为动作、基础服务类型、模型、chunk/字符数量和净化错误类别；焦点元素
  日志只记录字符数与控件元数据，DeepSeek 解码错误不再记录原始 SSE payload。
- 为 9 个新增 String Catalog key 同步 6 个 locale，并更新中英文完整用户指南。
- 由独立测试 Agent 添加服务选择、Prompt 隔离、逐 chunk 写入、回退边界、取消与日志
  隐私测试，并加入 EasydictTests target。

### 设计意图

动作只持久化服务实例 identifier，不复制模型、endpoint 或凭据，确保“服务”页面继续
作为传输配置的唯一来源。追加要求只能补充默认任务，避免把普通查询的 Custom Prompt
误用于翻译或润色。失败状态机以“是否已写入第一个非空 chunk”为边界，既维持流式首字
响应，也避免两个模型的输出被拼在同一段文本中。

### 验证

- Focused `xcodebuild test`：`TEST SUCCEEDED`，18 tests / 2 suites 全部通过。
- `swiftformat --lint`：15 个变更 Swift 文件均通过，`0/15 files require formatting`。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过，9 个新增 key 均覆盖全部 6 个 locale。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- 测试和静态验证未调用 BuiltInAI、Custom OpenAI 或其他 provider API。

### 受影响文件

- `Easydict/Swift/Feature/ActionManager/ActionManager.swift`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/Swift/Feature/HTTPServer/QueryService+Extension/QueryService+Request.swift`
- `Easydict/Swift/Feature/HTTPServer/QueryService+Extension/StreamService+Request.swift`
- `Easydict/Swift/Service/AITool/PolishingService.swift`
- `Easydict/Swift/Service/DeepSeek/DeepSeekService.swift`
- `Easydict/Swift/Service/Model/QueryServiceFactory.swift`
- `Easydict/Swift/Service/OpenAI/ChatMessage.swift`
- `Easydict/Swift/Service/OpenAI/StreamService+Prompt.swift`
- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/Swift/Utility/SystemUtility/FocusedElementInfo.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/AdvancedTab.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/TextReplacementSettingsSection.swift`
- `Easydict/App/Localizable.xcstrings`
- `EasydictTests/Service/TextReplacementServiceTests.swift`
- `EasydictTests/Service/TextReplacementStreamTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/user-docs/en/GUIDE.md`
- `docs/user-docs/zh/GUIDE.md`
- `docs/exec-plans/completed/2026-08-25-text-replacement-online-services.md`
- `docs/histories/2026-08/2026-08-26-text-replacement-online-services.md`

### 后续事项

- 未在真实 BuiltInAI、Custom OpenAI 或微信编辑框中发起模型请求，以避免擅自使用用户
  凭据或付费额度。发布前应在已授权辅助功能且凭据有效的环境中确认两种服务的流式首字
  响应，以及微信兼容模式下的焦点和替换行为。

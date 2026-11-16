## 2026-11-16 | 任务：增加 Qwen-MT 翻译服务

**Links:** [Issue #1114](https://github.com/tisfeng/Easydict/issues/1114)、
[PR #1406](https://github.com/tisfeng/Easydict/pull/1406)、
[执行计划](../../exec-plans/completed/2026-11/2026-11-16-add-qwen-mt.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

为 Easydict 增加 Qwen-MT 支持，从已有 fork 向上游提交 PR，并提供可先行使用、
后续能替换为官方版本的个人构建。使用本机配置完成真实服务验证。

### 变更

- 新增独立的 `QwenMTService`，默认使用 `qwen-mt-flash`，提供 Plus 和 Lite。
- 发送单条原始 user 消息和顶层 `translation_options`，映射源/目标语种，
  支持自动源语言、简繁中文及 Lite 的语言限制。
- Flash/Lite 复用增量 SSE transport，Plus 使用完整 JSON 响应；复用既有取消
  控制与结果处理。
- Qwen-MT 保留接口返回的引号、标签及空白，不执行通用聊天包装清理；
  其他流服务沿用原有清理行为。
- 增加服务注册、七种语言的名称、图标和 Xcode 源码/测试引用。
- 增加专属测试及中英文配置说明，覆盖地域 Endpoint 与翻译专用行为。
- 已构建并安装可日常使用的个人版本，保留官方 bundle ID。

### 设计意图

Qwen-MT 的翻译参数和消息契约不同于通用聊天服务。独立服务使原文与语种直接传入
接口，同时复用已有设置、请求生命周期和结果展示。Plus 使用完整响应以避免累计流
重复拼接；服务只提供翻译，不增加通用聊天提示词或词典分析。

接口依据 [Qwen-MT 官方说明](https://help.aliyun.com/zh/model-studio/machine-translation)
及 [API 参考](https://www.alibabacloud.com/help/en/model-studio/qwen-mt-api)。

### 验证

- SwiftFormat、Swift 语法解析、工程 plist lint、JSON/XML 解析、本地化与工程引用
  检查及 `git diff --check` 通过。
- Release 构建及 `Default` 计划的 `QwenMTServiceTests` 通过：4 项测试，
  其中传输策略的参数化用例覆盖三个默认模型。
- `LocalEnvironment` 真实译文测试通过：Flash、Plus、Lite 英文转简体中文，
  Flash 英文转繁体中文；使用本机已配置凭据，对实际返回的关键文字做断言。
- 自动审查指出的合法引号和 `<think>` 内容丢失问题已修正。Lite、Plus 的 4 个
  真实响应回归用例通过，逐块与最终结果均等于接口原始内容；共 8 个真实接口用例通过。
- 设置界面“验证”成功；正常输入 `The world is changing.`，分别切换三个模型，
  均显示正确译文。脱敏的设置和翻译截图保存在仓库外，用于 PR 交付。
- 最终安装版通过 URL scheme 输入带引号的句子，Lite 译文完整保留引号；
  回归截图已保存，所选模型恢复为 Flash。
- 最终代码 review 未发现有证据支持的阻断缺陷；UI 取消操作未单独实测。
- 本机 Release 测试使用命令行 ad hoc 签名与显式 Release 测试宿主。
  上游 `MDictReaderTests.swift` 引用了只在 Debug 编译的 helper，本次定向测试
  通过 `EXCLUDED_SOURCE_FILE_NAMES=MDictReaderTests.swift` 排除该无关文件；
  未修改仓库测试或持久工程配置。
- 构建产物与安装副本均通过 `codesign --verify --deep --strict`。
  界面验收后已恢复临时偏好，并正常启动唯一安装版实例。
- 正式 PR #1406 已提交至上游 `dev`，创建后的身份、head 和正文回读验证通过。

### 受影响文件

- `Easydict/Swift/Service/QwenMT/`
- `Easydict/Swift/Service/Model/QueryServiceFactory.swift`
- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/Swift/Service/OpenAI/StreamService+UpdateResult.swift`
- `Easydict/objc/Service/Model/EZEnumTypes.h`
- `Easydict/objc/Service/Model/EZEnumTypes.m`
- `Easydict/App/Assets.xcassets/service-icon/QwenMT.imageset/`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `EasydictTests/Service/QwenMT/QwenMTServiceTests.swift`
- `docs/user-docs/en/SERVICES.md`
- `docs/user-docs/zh/SERVICES.md`
- 本任务 plan/history。

### 后续事项

- 上游发布包含该支持的正式版本后，可使用官方应用替换个人构建；
  相同 bundle ID 保留现有服务配置。

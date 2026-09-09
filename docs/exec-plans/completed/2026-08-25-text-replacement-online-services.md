# 翻译与润色替换在线服务

**Status:** completed
**Created:** 2026-08-25
**Updated:** 2026-08-26
**Owner:** ericpan
**Links:** 当前用户请求

## 任务契约

- 任务模式：implementation
- 用户目标：保持逐 chunk 流式写回，为翻译并替换和润色并替换分别增加已有
  OpenAI 兼容服务选择与可空追加要求，并实现明确的单次回退和中断提示。
- 允许动作：修改产品代码、设置 UI、Defaults、String Catalog、中英文用户文档、
  行为测试、Xcode 工程元数据、执行计划和变更历史；运行本地格式、构建和测试检查。
- 允许修改路径：Easydict/、EasydictTests/、Easydict.xcodeproj/project.pbxproj、
  docs/exec-plans/、docs/histories/、docs/user-docs/。
- 预期交付物：可配置的两个流式替换动作、追加要求、服务能力目录、失败回退与安全日志、
  自动化测试、本地化和用户指南。
- 验收标准：默认服务和 Prompt 行为不变；完整 CustomOpenAI#uuid 生效；服务页
  配置继续作为唯一模型与凭据来源；首 chunk 前最多回退一次；部分输出后不混合模型；
  全部目标检查通过。

## 自动提交状态

- 自动提交资格：eligible
- 初始暂存区：empty
- 自动提交结果：completed，单个本地提交，不 push。

## 输入来源

- 用户明确请求：按已确认方案实现在线服务选择、两个独立追加要求和流式失败状态机。
- 仓库规则：AGENTS.md、docs/agents/ 与 docs/architecture/overview.md。
- 附件或引用材料：GitHub dev 分支地址及用户提供的实施计划。
- 仅作为证据的内容：此前对 ActionManager、QueryServiceFactory 和现有服务的静态调查。

## 目标

让两个文本替换动作使用用户选定的已有远程 OpenAI 兼容服务实例，同时维持即时流式
写回体验、当前焦点与微信兼容策略，并在失败时给出不泄露敏感内容的确定反馈。

## 范围

- 包含范围：Defaults、服务能力元数据与候选目录、替换动作 Prompt、流式编排、
  单次回退、设置 UI、全 locale 文案、中英文用户文档、测试与安全日志。
- 不包含范围：Gemini、Claude、Ollama、CLI 和传统翻译服务；动作级模型覆盖；
  Prompt 模板变量；流式回滚；微信拖选与焦点机制；Keychain 迁移；真实付费 API 调用。

## 背景

- 原行为：翻译固定使用 BuiltInAI，润色固定使用 Polishing，响应按 chunk 立即写回。
- 相关文件：ActionManager.swift、QueryServiceFactory.swift、StreamService Prompt、
  PolishingService.swift、AdvancedTab.swift 和 Defaults.Keys+Extension.swift。
- 约束：服务 identifier 必须保留 CustomOpenAI UUID；动作 Prompt 必须压过服务页
  Custom Prompt；日志不得记录选中文字、Prompt、响应、凭据或原始 provider payload。

## 风险与缓解

- 风险：通用 OpenAI 服务的自定义 Prompt 覆盖动作语义。
  - 缓解措施：为替换动作建立内部 Prompt context，并在请求消息构造入口显式优先处理。
- 风险：失败后回退混入两家服务的输出。
  - 缓解措施：只允许首个有效 chunk 前回退一次；任何已写入输出都保留且只提示中断。
- 风险：已删除 Custom OpenAI identifier 残留。
  - 缓解措施：执行与展示前用三类窗口配置并集校验，失效时重置到动作默认服务。
- 风险：UI 候选和运行时能力漂移。
  - 缓解措施：服务注册元数据作为统一能力来源，并用无网络测试锁定过滤行为。
- 风险：焦点元素或 provider 解码日志泄露原文或响应正文。
  - 缓解措施：焦点日志只保留字符数和控件元数据，provider 解码失败只记录错误类别。

## 里程碑

- [x] 确认范围、初始工作树和约束。
- [x] 实现 Defaults、能力目录、Prompt 与流式状态机。
- [x] 实现设置 UI、本地化和中英文用户文档。
- [x] 由独立测试 Agent 添加行为测试并更新工程引用。
- [x] 完成格式、构建、测试和数据文件验证。
- [x] 记录历史、归档计划并按规则执行自动本地提交。

## 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict
  -disableAutomaticPackageResolution -skipPackageUpdates -packageAuthorizationProvider netrc
  -only-testing:EasydictTests/TextReplacementServiceTests
  -only-testing:EasydictTests/TextReplacementStreamTests`：通过，`TEST SUCCEEDED`，
  Swift Testing 执行 18 tests / 2 suites。
- `swiftformat --lint --config .swiftformat <15 个变更 Swift 文件>`：通过，
  `0/15 files require formatting`；使用 `/tmp` 中的官方 SwiftFormat 0.62.1，未安装系统工具。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过；9 个新增 key 均覆盖
  en、es、ja、sk、zh-Hans 和 zh-Hant。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- 静态检查：动作每收到非空 chunk 即调用现有插入策略；只在零 chunk 的空响应或失败时
  回退一次；删除选择才重置 Defaults，临时网络、凭据和模型错误不改用户选择。
- 手动检查：未调用真实模型或用户付费 API；BuiltInAI、Custom OpenAI 与微信中的
  跨应用首字响应仍需用户在有权限和有效凭据的运行环境中确认。

## 决策记录

- 2026-08-25：保持现有逐 chunk 写回；Custom OpenAI 非流式配置可只返回一个完整 chunk。
- 2026-08-25：追加要求只作为默认任务之后的附加 user instruction，不支持覆盖或模板。
- 2026-08-25：首 chunk 前的缺失配置、空响应和请求失败回退一次；部分写入后不回退。
- 2026-08-25：删除的服务选择重置为 BuiltInAI 或 Polishing；临时网络和密钥错误不重置。
- 2026-08-26：服务模型为空时在发出请求前归类为配置失败，并进入同一单次回退路径。

## 进度记录

- 2026-08-25：确认 dev 工作树和暂存区为空，读取仓库规则与 macOS SwiftUI 构建技能。
- 2026-08-25：完成服务能力、动作 Prompt、流式编排、设置 UI、本地化和用户指南。
- 2026-08-26：独立测试会话完成 18 项无网络行为测试；最终增量构建与测试通过。
- 2026-08-26：完成安全日志审计、格式检查、数据校验、历史记录和计划归档。

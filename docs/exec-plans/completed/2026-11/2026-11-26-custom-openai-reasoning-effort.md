# Custom OpenAI 思考强度设置

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->
<!-- 本模板只用于多步骤、跨模块或高风险的执行任务。 -->

- 状态：completed
- 创建日期：2026-11-26
- 负责人：Claude agent (Claude Agent SDK)
- 关联 Issue/PR：[#1353](https://github.com/tisfeng/Easydict/issues/1353)；相关未合并 PR #1364

## 执行上下文

- **Agent Name:** `Claude agent (Claude Agent SDK)`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

Custom OpenAI 设置页没有思考强度选项，`StreamService.reasoningEffort` 对它固定返回 `nil`。
共享的 `ReasoningEffort`（off/high/max）为 DeepSeek 设计：`max` 不是 OpenAI 标准值，`off`
只是省略字段，不能关闭思考，因此不能直接给 Custom OpenAI 打开 `supportsReasoningEffort`。

## 目标与范围

- 目标结果：Custom OpenAI 设置页在“使用模型”下方提供思考强度下拉框，取值 Default（不发送）、
  none、minimal、low、medium、high、xhigh，按所选值在请求体中发送 `reasoning_effort`。
- 允许修改路径：`Easydict/Swift/Service/CustomOpenAI/`、`Easydict/Swift/Service/OpenAI/`、
  `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`、`StreamConfigurationView.swift`、
  `Localizable.xcstrings`、`project.pbxproj`、`EasydictTests/Service/OpenAI/`、本计划与同名 history。
- 同任务 history：`docs/histories/2026-11/2026-11-26-custom-openai-reasoning-effort.md`
- 用户限制：先调研 GitHub issue/PR；可调用 Antigravity（`agy`）辅助开发或测试。
- 非目标：不改 DeepSeek 与共享 `ReasoningEffort`；不实现 #1364 的 extra body 与自由文本；不 push、不建 PR。
- 验收标准：默认不发送字段，保持现有用户请求不变；选择档位后流式与非流式请求体均含对应值；
  多个 Custom OpenAI 实例独立保存；构建与相关测试通过；设置页截图。

## 工作计划

1. 新增 `OpenAIReasoningEffort` 枚举与独立存储键，映射到 `ChatQuery.ReasoningEffort`。
2. `BaseOpenAIService` 以 `supportsOpenAIReasoningEffort` 门控覆盖 `reasoningEffort` 与 `ocrTranslationConfiguration`，`CustomOpenAIService` 开启。
3. `StreamConfigurationView` 增加门控下拉框；补全 7 个 locale 文案。
4. 增加请求体编码测试；构建、测试、界面实测截图。
5. Review、history、归档计划、本地提交。

## 风险与决策

- 新存储键 `OpenAIReasoningEffort`，避免与 `.reasoningEffort` 槽位的 `ReasoningEffort` 类型冲突。
- 默认 Default（不发送），避免非推理模型或不支持该字段的网关返回 400。
- `xhigh` 通过 SDK 的 `.customValue` 发送；`none` 是否被接受取决于提供方，文案中不承诺关闭效果。

## 进度

- [x] 实现
- [x] 验证
- [x] Review
- [x] 交付

## 验证

- `xcodebuild build`（命令行覆盖 `CODE_SIGN_ENTITLEMENTS` 为空 entitlements，因本机无 Debug entitlement 所需 provisioning profile）：成功。
- `xcodebuild test-without-building -only-testing:EasydictTests/OpenAIReasoningEffortTests -only-testing:EasydictTests/OpenAIStreamTaskControlTests`：7 个测试（含 6 个参数化用例）全部通过。
- 界面实测：Debug 构建中添加 Custom OpenAI，思考程度下拉框位于“使用模型”下方，默认“Default (not sent)”，7 个选项齐全；选 Medium 后回显并写入按 uuid 隔离的键。
- 未验证：真实提供方端点请求（未使用用户密钥）。

## 完成条件

构建与测试通过，设置页截图确认，history 已写，计划归档，本地提交完成。

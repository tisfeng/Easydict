## 2026-11-11 | 任务：要求服务测试验证真实结果

**Links:** [构建与测试](../../agents/build-and-test.md#测试与验证原则)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

要求服务测试使用真实服务和本机配置，对实际结果做断言，并移除 DeepSeek 的虚假请求测试。

### 变更

- 在测试规则中要求真实 endpoint、本机凭据和实际响应断言。缺配置时记录跳过原因。
- 删除使用虚构地址和凭据的 `DeepSeekOCRTests.swift` 及 Xcode 工程引用。保留 `LocalEnvironment` 中的真实 DeepSeek 公式识别和流式翻译测试。

### 设计意图

使用应用的服务配置和调用路径验证真实响应，沿用两份测试计划的配置隔离。

### 验证

- `xcodebuild test -testPlan LocalEnvironment -only-testing:EasydictTests/DeepSeekFormulaImageTests` 实测 2 项通过，覆盖真实流式识图及翻译过程中的公式渲染。
- `plutil -lint` 和 `git diff --check` 通过。源码和 Xcode 工程中已无旧测试引用。

### 受影响文件

- `docs/agents/build-and-test.md`
- `EasydictTests/Service/DeepSeek/DeepSeekOCRTests.swift`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 本次验证覆盖 DeepSeek 真实用例。

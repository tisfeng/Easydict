## 2026-11-11 | 任务：统一 Xcode 测试计划

**Links:** [PR #1391](https://github.com/tisfeng/Easydict/pull/1391) · [执行计划](../../exec-plans/completed/2026-11/2026-11-11-local-environment-tests.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

保留 Default 和 LocalEnvironment 两份计划。默认 ⌘U 排除依赖本机配置的用例，命令行和 Xcode 支持单独运行。

### 变更

- 共享 scheme 按 `.requiresLocalEnvironment` 标签筛选测试，移除 Codex 和 DeepSeek 专用计划。
- 将四个真实 Codex 和 DeepSeek 用例迁移到 Swift Testing。给其余依赖本机配置的用例加标签，并按注册元数据拆分全服务验证，保留 Google 等免配置服务的默认覆盖。
- 将两个计划加入项目导航器，记录 Xcode 和命令行入口。

### 设计意图

新服务的真实用例按环境依赖加标签。免配置的在线用例与测试替身继续在默认计划执行。

### 验证

- `xcodebuild -showTestPlans` 只列出 Default 和 LocalEnvironment。
- `xcodebuild test` 使用共享默认计划，筛选 9 个带标签的用例与 3 个对照用例，报告只记录 3 个对照用例并全部通过。
- `xcodebuild test -testPlan LocalEnvironment -only-testing:…` 单独运行真实 Codex OCR，1 项通过。LocalEnvironment 的 MDict 与 Apple OCR 对照运行只执行 MDict。
- 手动检查：Xcode 切换 LocalEnvironment，点击同一项 Codex OCR 左侧的运行按钮，测试报告 1 项通过。结束后切回 Default。

### 受影响文件

- `EasydictTests/` 下的共享测试计划、OCR 与服务测试及标签定义。
- `Easydict.xcodeproj/` 下的工程文件与共享 scheme。
- `docs/agents/build-and-test.md`。

### 后续事项

- 本次按入口和筛选范围验证。未执行完整 Default 或全部需要本机配置的用例。

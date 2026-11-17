## 2026-11-11 | 任务：让 Codex 公式测试读取本机模型

**Links:** [PR #1391 审查评论](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4535617710)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复本机 Codex 公式测试可能误用托管模式模型的问题。

### 变更

- 公式识图和流式翻译用例共用本机模型选择逻辑，直接读取 `.localCLI` 模型配置。
- 配置留空时使用本机 CLI 声明的默认模型。显式指定的模型不在 CLI 列表中时，模型查找报错。

### 设计意图

测试固定由本机 CLI 执行，因此用同一模式的模型配置进行模型查找。临时测试实例继续使用独立 UUID。

### 验证

- `xcodebuild build-for-testing` 使用 `LocalEnvironment` 成功构建。
- `xcodebuild test-without-building` 使用仅对测试进程生效的启动参数，选中托管模式并将其模型设为本机列表未提供的 `gpt-5.5`。留空本机模型时，真实识图与流式翻译均通过。
- 将本机模型也设为 `gpt-5.5` 时，识图用例在模型查找阶段按预期报错。
- 显式指定本机 CLI 提供的非默认模型 `gpt-6-sol` 时，真实识图与流式翻译均通过。
- 显式指定 `gpt-5.6-luna` 时，流式翻译两次通过。两次真实识图输出均未满足现有参考编号和公式编号断言。

### 受影响文件

- `EasydictTests/Service/CodexCLI/CodexFormulaImageTests.swift`

### 后续事项

- `gpt-5.6-luna` 的识图内容未通过该测试样本的断言。

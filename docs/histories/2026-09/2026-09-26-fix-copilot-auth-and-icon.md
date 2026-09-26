## 2026-09-27 | 任务：修复 Copilot 登录复用与服务图标

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-26-fix-copilot-auth-and-icon.md) ·
[CLI 配置目录](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference) ·
[官方 Copilot 图形](https://github.com/primer/octicons/blob/main/icons/copilot-24.svg)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

排查终端已登录 Copilot 而 Easydict 翻译提示未登录的问题，参考 Codex 补齐服务图标；确认方案后执行。

### 变更

- 新增 `GitHubCopilotEnvironment`：合并 GUI 与登录 shell 的 PATH，按白名单补齐认证和代理变量；
  shell 输出只在内存处理，不写入日志。
- 在覆盖 `COPILOT_HOME` 之前解析原配置目录，使用 JSON5 解码兼容带注释的 `config.json`；
  每次请求仅编码 `lastLoggedInUser`、`loggedInUsers` 中的 host/login 到临时目录。
- 账户令牌仍由 CLI 从钥匙串读取；不复制令牌、用户工具、hooks、插件、信任目录或模型设置。
  临时目录权限为 0700，账户标识文件权限为 0600，沿用成功、失败和取消清理路径。
- 添加 `GitHubCopilot.imageset`，使用官方 Octicons 图形、白色圆角背景、256×256 PNG 和 2x 配置。
  MIT 许可及来源说明随应用资源打包。
- 更新工程引用；纠正构建规则与旧 history 对钥匙串权限的过度归因。

### 设计意图

官方文档说明配置目录同时存放认证状态。实际 GUI 进程只继承系统 PATH，原 Runner 的空配置目录
又遗漏账户标识，导致 CLI 无法使用相同的认证上下文。保留会话目录隔离并只携带最小账户标识，
可让 CLI 自行查找钥匙串，而无需读取 token 或复制完整用户配置。白名单环境恢复参考 Codex，
没有为局部修复引入跨服务重构。

### 验证

- `xcodebuild build`：Debug 构建通过，使用 checkout 专属 agent DerivedData。
- SwiftFormat 与 SwiftLint：仅检查/格式化改动 Swift 文件，通过；构建使用
  `EASYDICT_RELEASE_PACKAGING=YES` 跳过全仓库格式化，避免无关改动。
- `xcodebuild test -only-testing:EasydictTests/CodexCLIRunnerEnvironmentTests`：16 项现有测试通过。
  这些测试检查参考实现，不代表新增 Copilot helper 有独立单元覆盖；本任务未新增测试。
- 现有 `ServiceTests.testAllServicesValidateTranslation` 中 Copilot 的真实请求成功：CLI 1.0.88，
  `exitCode=0`，耗时 9.0 秒，返回英文译文，`toolRequests=[]`，stderr 为空。
- 全服务测试整体失败：MDict 缺少词典，OpenAI/GitHub/Gemini 上游或配置错误，MiniMax 缺少密钥，
  ClaudeCode 未登录；后续还出现测试宿主退出/超时重启记录。此项不记录为通过，不扩大修改到其他服务。
- `assetutil --info`：构建产物包含名为 `GitHubCopilot` 的 256×256、2x 图像，图标许可文件已打包。
  已目视检查生成的 PNG；原有两处界面按服务名加载该资源。
- `git diff --check`、资源 JSON 检查和 `plutil -lint`：通过。
- 请求完成后临时 Copilot 目录无残留；随后检查原配置文件摘要与原会话目录清单，均未变化。
- 真正交互界面的翻译、取消及浅色/深色切换未完成：多次通过 UI 工具选择新构建均报
  `timeoutReached`。应用已启动；主线程采样正常等待事件，没有证明应用卡死。
- Review：以 `888cb91cc3bc5f2bff37e5ca87fd2f9210ffaf61` 为基线，首次写入前工作树与索引干净；
  对任务文件保存内容摘要后审查白名单、JSONC 兼容、账户刷新、进程环境、清理路径和资产引用。
  未发现需修复的 finding；最终生产代码与已审查快照一致。相较复制完整配置或取消隔离，当前方案
  范围更小并保留原有工具及会话隔离边界。

### 受影响文件

- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotEnvironment.swift`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotRunner.swift`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilot-LICENSE.txt`
- `Easydict/App/Assets.xcassets/service-icon/GitHubCopilot.imageset/`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/agents/build-and-test.md`
- `docs/histories/2026-09/2026-09-24-github-copilot-service.md`
- 本记录与关联计划。

### 后续事项

- UI 自动化恢复后补做真实界面的取消与浅色/深色显示验证。
- 本次复用钥匙串账户；不支持复制 CLI 明文存储的 token，现有环境变量和 `gh` 回退由 CLI 处理。

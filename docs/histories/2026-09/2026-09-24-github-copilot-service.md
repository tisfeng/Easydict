## 2026-09-24 | 任务：新增 GitHub Copilot 翻译服务（本机 CLI 模式）

**Links:** [`docs/exec-plans/completed/2026-09/2026-09-24-github-copilot-service.md`](../../exec-plans/completed/2026-09/2026-09-24-github-copilot-service.md)

### 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

参考现有 ChatGPT auth 登录实现与第三方 `pi-agent` 的 GitHub Copilot 认证实现，为 Easydict
新增一个使用 Copilot 订阅的翻译服务，先给出方案；确认后按「先做本机 CLI 模式」执行。

### 变更

- 新增 `Easydict/Swift/Service/GitHubCopilot/`：`GitHubCopilotService`、`GitHubCopilotRunner`、
  `GitHubCopilotEventParser`、`GitHubCopilotError`、`GitHubCopilotEffort`、`GitHubCopilotModel`、
  `GitHubCopilotLogger`、`GitHubCopilotDebugWindow`。
- 新增 `GitHubCopilotServiceConfigurationView`（CLI 状态行、模型输入、推理程度选择）。
- 接入 `EZServiceTypeGitHubCopilot`（`.h`/`.m`）、`QueryServiceFactory` 注册、
  服务启用风险确认、`AppPathManager+Logs` 日志目录。
- `Localizable.xcstrings` 新增 26 个 `service.github_copilot.*` key（en/es/ja/sk/zh-Hans/zh-Hant）。
- 同步 `project.pbxproj` 的 file reference、build file、group 与 Sources。
- `docs/user-docs/{en,zh}/GUIDE.md` 新增 GitHub Copilot 使用说明。

### 设计意图

- **选择本机 CLI 而非直连 HTTP**：`api.githubcopilot.com` 是 Copilot 官方客户端的内部端点，
  非公开 API，GitHub 已对第三方客户端返回 `403 Access to this endpoint is forbidden`，并推出
  官方 `github/copilot-sdk` 作为合规替代。托管官方 `copilot` CLI 沿用官方认证与端点，风险面
  与既有 Codex/Claude 服务一致。
- **不读取任何凭据**：登录态由 CLI 自己保存在系统钥匙串，Easydict 不读取、不保存、不打印 token。
- **工具面清零**：`-p` 模式默认加载 19 个工具。实测传 `--available-tools <不存在的工具名>`
  后 CLI 自报 `tool_count: 0`；而 `--excluded-tools` 逐个排除只从 19 降到 11，会漏掉内置工具，
  因此不用。该变参选项放在参数末尾，避免吞掉后续 flag。
- **配置目录隔离**：实测 `-p` 运行会把提示词原文写入 `<COPILOT_HOME>/session-state/`，
  且默认落在用户自己的 `~/.copilot`。改为每次请求创建一次性沙箱（`COPILOT_HOME` + 空工作目录
  + `--log-dir`），进程退出后整体删除，翻译内容不留在用户 CLI 状态中；认证不受影响（凭据在钥匙串）。
- **固定 `--no-auto-update`**：CLI 默认自动下载新版本，会使行为随上游漂移。执行期间本机 CLI 即
  从 1.0.86 自更新到 1.0.88，印证了该固定的必要性。
- **不引入跨服务抽象**：`ClaudeCode`/`CodexCLI` 已是「一个服务一套 Runner/Parser/Logger」的既有
  惯例，本次沿用，不在同一任务内做重构。
- **模型字段保持自由文本**：CLI 从服务端拉取模型目录，无法离线枚举，静态清单只作示例，留空则省略
  `--model` 使用 CLI 自身默认模型。

### 验证

- `xcodebuild build`（`-workspace Easydict.xcworkspace -scheme Easydict`，checkout 专属
  `-derivedDataPath`）：通过，无 SwiftLint 诊断。
- `git diff --check`：通过。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- 解析器断言（19 项，基于真实 CLI JSONL 样本，在临时目录编译运行，未进仓库）：全部通过，覆盖
  文本增量提取、`reasoning_delta` 与 `assistant.message` 不重复计入、工具请求计数（含空数组、
  非空数组、`null`、形状漂移 fail-closed）、usage 解析、错误分类（模型不可用/未登录/限额/stderr
  噪声过滤/stdout 优先）。
- 端到端隔离实测（本机 `copilot` 1.0.88，与实现完全相同的参数组合，并额外清空环境变量以模拟
  GUI 启动上下文）：`exitCode 0`、`tool_count: 0`、`toolRequests: 0`，模型正常返回文本；
  会话状态全部落在沙箱目录，真实 `~/.copilot` 无泄漏；诱饵文件未被读写。此项证明调用模式
  （参数、沙箱、环境）本身正确。
- 沙箱生命周期实测：应用内测试宿主执行过一次真实请求（该次因凭据问题失败退出），运行结束后
  `/tmp/easydict-copilot-*` 残留数为 0，确认终止处理与失败路径的清理都生效。
- `xcodebuild test`（集成用例 `ServiceTests.testAllServicesValidateTranslation`）：本机失败，
  8 个服务报错，其中 7 个为既有服务（MDict 未导入词典、OpenAI/DeepL/Gemini 网络或密钥、
  MiniMax 无密钥、GitHub Models 端点、ClaudeCode 未登录）。该用例要求所有已注册服务都成功，
  属环境依赖的集成测试；本仓库 CI 无测试 workflow、无 `xctestplan`，故无 CI 影响。
- 本服务在该集成测试中的失败原因已定位：应用内子进程报
  `No authentication information found.`，而同一二进制在普通进程上下文中可正常认证并翻译
  （见上条端到端实测）。这与既有 ClaudeCode 服务在同一测试中同样失败一致——两者都把凭据放在
  系统钥匙串，而 CodexCLI 使用 `~/.codex/auth.json` 文件凭据因而通过。属测试宿主进程链的钥匙串
  读取条件，不是本次实现的调用或解析缺陷。
- 未验证：真机在应用内完成一次翻译与取消操作（需交互式运行已签名应用；测试宿主无法复现用户的
  钥匙串上下文）。

### 受影响文件

- `Easydict/Swift/Service/GitHubCopilot/`（8 个新文件）
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/GitHubCopilotServiceConfigurationView.swift`
- `Easydict/Swift/Service/Model/QueryServiceFactory.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `Easydict/Swift/Utility/AppPathManager/AppPathManager+Logs.swift`
- `Easydict/objc/Service/Model/EZEnumTypes.h`、`EZEnumTypes.m`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/user-docs/en/GUIDE.md`、`docs/user-docs/zh/GUIDE.md`
- `docs/exec-plans/active/2026-09-24-github-copilot-service.md`

### 后续事项

- 托管模式（Slice 2）：组件下载与版本固定，对齐 `CodexComponentStore` 的校验与事务安装模式。
- 未验证项：真机应用内端到端翻译与取消（测试宿主无法复现用户的钥匙串上下文）。
- 已知限制：CLI 的「未登录」可能同时来自钥匙串读取被拒，此时提示用户执行 `copilot login`
  不会解决问题；无法可靠区分两种原因。
- 若上游 CLI 变更 `--available-tools` 语义或事件结构，工具隔离守卫与解析器需要相应复核。
- GitHub Enterprise（`--host`）支持未实现。

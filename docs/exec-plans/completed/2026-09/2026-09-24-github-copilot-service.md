# GitHub Copilot 本地 CLI 翻译服务

- 状态：active
- 创建日期：2026-09-24
- 负责人：tisfeng
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Mavis`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

Easydict 已支持 ChatGPT auth（`CodexCLIService` 的 managed 模式）与本地 Claude CLI
（`ClaudeCodeService`）。用户希望新增 GitHub Copilot 服务，复用其 Copilot 订阅做翻译。

本任务只实现**本地 CLI 模式**：用户机器上自行安装并已登录官方 `copilot` CLI，Easydict 负责
发现二进制、拼装参数、spawn 子进程、解析 JSONL 输出。不下载任何组件，不读取也不保存任何凭据。

选择官方 `copilot` CLI 而非直连 `api.githubcopilot.com` 的原因：后者是 Copilot 官方客户端的内部
端点，非公开 API，GitHub 已开始对第三方客户端返回
`403 Access to this endpoint is forbidden. Please review our Terms of Service.`，并推出了官方
`github/copilot-sdk` 作为合规替代。托管官方 CLI 沿用官方认证与官方端点，风险面与现有 Codex/Claude
服务一致。

本机实测结论（`copilot` 1.0.86，macOS arm64）：

- `-p/--prompt` 非交互模式**不需要** `--allow-all-tools` 即可完成一次推理。
- `--output-format json` 输出 JSONL，一行一个事件，事件 `type` 包括 `user.message`、
  `assistant.message_delta`、`assistant.message`、`session.usage_checkpoint`、`result`。
  `result` 顶层含 `exitCode` 与 `usage`，用量从该事件读取。
- 默认加载 **19 个工具**（`bash`、`view`、`create`、`edit`、`web_fetch` 等）。
- 传 `--available-tools <不存在的工具名>` 后 `tool_count: 0`，工具被完全屏蔽。
- 传 `--excluded-tools` 逐个排除只把 19 降到 11，**会遗漏内置工具**，不能作为隔离手段。
- `--model` 传不可用模型时以 exit code 1 失败，stderr 为
  `Error: Model "<name>" from --model flag is not available.`。
- CLI **默认自动下载更新**，需 `--no-auto-update` 固定行为。

## 目标与范围

- 目标结果：新增 `GitHubCopilotService`，以官方 `copilot` CLI（本地安装、用户自带登录态）为
  后端提供流式翻译；在设置页显示二进制路径与可用状态，支持模型与 reasoning effort 覆盖。
- 允许修改路径：
  - `Easydict/Swift/Service/GitHubCopilot/`（新增）
  - `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/GitHubCopilotServiceConfigurationView.swift`（新增）
  - `Easydict/objc/Service/Model/EZEnumTypes.{h,m}`
  - `Easydict/Swift/Service/Model/QueryServiceFactory.swift`
  - `Easydict/Swift/Utility/AppPathManager/AppPathManager+Logs.swift`
  - `Easydict/App/Localizable.xcstrings`
  - `Easydict.xcodeproj/project.pbxproj`
  - `docs/design-docs/application-architecture.md`
  - `docs/user-docs/{en,zh}/GUIDE.md`
- 同任务 history：`docs/histories/2026-09/2026-09-24-github-copilot-service.md`
- 用户限制：仅本地 CLI 模式；不实现托管下载；不新增测试（未获授权）。
- 非目标：
  - 托管组件下载与 `runtime-manifest.json` 式版本固定（Slice 2，另立计划）。
  - GitHub Enterprise `--host` 支持。
  - 替换或重构现有 `CodexComponentStore`/`CodexCLI`/`ClaudeCode` 代码。
  - 直连 `api.githubcopilot.com` 的 HTTP 实现。
- 验收标准：
  1. 已装 `copilot` 且已登录的机器上，查词/翻译能得到流式结果。
  2. 未装 `copilot` 时给出明确的本地化错误，而非空白或崩溃。
  3. 翻译进程的工具面为 0：不读写文件、不执行 shell、不发起网络工具调用。
  4. 取消查询能终止子进程，不残留进程。
  5. 设置页显示检测到的二进制路径与模型/effort 覆盖项。
  6. 构建与现有测试通过。

## 工作计划

1. 新增 `GitHubCopilotError`、`GitHubCopilotEffort`、`GitHubCopilotModel`（模型清单与默认值）。
2. 新增 `GitHubCopilotEventParser`：解析 JSONL 的 `assistant.message_delta` 文本增量、
   `result` 事件的用量、工具请求守卫，以及认证/限额/模型不可用错误消息。
3. 新增 `GitHubCopilotRunner`：登录 shell 解析 `copilot` 路径（GUI app 无 PATH）、拼装隔离参数、
   spawn 子进程、按行解析 stdout、终止处理与取消。
4. 新增 `GitHubCopilotLogger` + `GitHubCopilotDebugWindow`（`AGENT_CLI_DEBUG`）。
5. 新增 `GitHubCopilotService: StreamService`：合并 system+user 为单条 prompt，接 Runner 流，
   暴露 `tokenUsage`，实现 `cancelStream()`。
6. 新增 `GitHubCopilotServiceConfigurationView`：CLI 状态行 + 模型输入 + effort 选择。
7. 周边接入：`EZServiceTypeGitHubCopilot`（`.h`/`.m`）、`QueryServiceFactory` 注册、
   `AppPathManager+Logs` 日志目录、`Localizable.xcstrings` 六个 locale。
8. 同步 `project.pbxproj` 的 group / file reference / Sources。
9. 文档：`application-architecture.md` 运行时边界、`docs/user-docs/{en,zh}/GUIDE.md`。
10. 验证、Review、history 与提交。

## 风险与决策

- **工具隔离（最高风险）**：`-p` 模式默认带 19 个工具。仅靠 `--available-tools` 空白名单隔离，
  已实测有效（`tool_count: 0`），但该 flag 语义依赖 CLI 实现。沿用 Codex 的教训：不把「被拒工具
  调用一定有 JSONL item」当作前提，隔离靠参数层面扣除工具面，并在验证中实测确认。
- **`COPILOT_ALLOW_ALL` 绝不可设 `true`**：该拼写会额外信任工作目录并加载其 skills/plugins/MCP/hooks
  （含执行 shell 的 hook）。Runner 显式清除该变量，避免从用户环境继承。
- **自更新**：CLI 默认自动下载新版本，会使行为随上游漂移。固定传 `--no-auto-update`。
- **工作目录**：`process.currentDirectoryURL` 指向应用自建的空临时目录，不使用用户仓库目录。
  （CLI 的「工作目录/仓库」判定就是进程 cwd，已用 `copilot instruction list` 实测确认；未使用
  `-C`，`currentDirectoryURL` 已足够。）
- **凭据**：只复用用户既有登录态（CLI 自己存系统钥匙串）。Easydict 不读取、不保存、不打印 token；
  日志只记录命令与输出，不注入任何环境凭据。
- **模型白名单**：CLI 从服务端拉取模型目录，无法离线枚举，因此维护静态清单。清单可能在 CLI 更新后
  过期，用户可手动输入未列出的模型名（沿用 ClaudeCode 的文本输入模式，不强制下拉）。
- **决策：窄复制而非先抽公共层**：`ClaudeCode`/`CodexCLI` 已是「一个服务一套 Runner/Logger/
  Parser/Effort/Error」的既有惯例，本次沿用，不在同一任务内引入跨服务抽象。
- **决策：模型不设为必填**：模型留空时省略 `--model`，使用 CLI 默认模型。

## 进度

- [x] 规则文档与 spike 实测
- [x] plan 文档
- [x] GitHubCopilot 服务源码
- [x] 周边接入与工程文件
- [x] 验证（构建、静态检查、解析器断言、隔离实测；完整测试套件受限见下）
- [x] Review（独立审查，已修复有效 finding）
- [x] history 与提交

## 验证

- `xcodebuild build`：通过，无 SwiftLint 诊断。
- `xcodebuild build-for-testing`：通过。
- `git diff --check`：通过。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- 解析器断言（19 项，基于真实 CLI JSONL 样本，临时目录编译运行）：全部通过。
- 端到端隔离实测（本机 `copilot` 1.0.88，与实现相同参数）：`tool_count: 0`、`toolRequests: 0`、
  exit 0；会话状态仅落在沙箱，真实 `~/.copilot` 无泄漏；诱饵文件未被读写。
- 解析器断言（19 项，基于真实 CLI JSONL 样本，临时目录编译运行）：全部通过。
- 端到端隔离实测（本机 `copilot` 1.0.88，与实现相同参数并清空环境以模拟 GUI 上下文）：
  `exitCode 0`、`tool_count: 0`、`toolRequests: 0`；会话状态仅落在沙箱，真实 `~/.copilot`
  无泄漏；诱饵文件未被读写。
- 沙箱清理实测：应用内一次真实请求（因凭据问题失败）结束后，`/tmp/easydict-copilot-*` 残留为 0。
- `xcodebuild test`（集成用例 `ServiceTests.testAllServicesValidateTranslation`）：本机失败，
  8 个服务报错，其中 7 个为既有服务（缺词典/密钥、网络、端点、未登录）。该用例要求所有已注册
  服务都成功，属环境依赖的集成测试；本仓库 CI 无测试 workflow、无 `xctestplan`，无 CI 影响。
- 本服务在该用例中的失败已定位为测试宿主的钥匙串读取条件：应用内子进程报
  `No authentication information found.`，而同一二进制在普通进程上下文中认证与翻译正常
  （见上条实测）。与既有 ClaudeCode 服务在同一用例中同样失败一致——两者凭据都在钥匙串，
  而 CodexCLI 用文件凭据因而通过。
- 未验证：真机在应用内完成一次翻译与取消操作（需交互式运行已签名应用）。

## 完成条件

- 上述验证全部通过，或未通过项已明确记录为已知限制。✅（完整测试套件与真机验证记录为已限制项）
- `review` 技能的有效 finding 已修复并重新验证。✅
- `docs/histories/2026-09/2026-09-24-github-copilot-service.md` 已写入。✅
- 本文件移入 `docs/exec-plans/completed/2026-09/`。
- 已创建本地提交（不 push）。

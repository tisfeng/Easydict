# CodexCLI 测试目录概览

该目录覆盖 Codex CLI 翻译服务的关键单元测试，重点是 CLI 参数构建、
JSONL 事件解析和服务注册。本目录不覆盖 UI 或子进程实际执行，
真实子进程行为依赖 `codex` 二进制和登录态，由开发者本地手工验证。

## 关键文件

- `CodexCLIRunnerTests.swift` 是核心测试套件，覆盖多类逻辑：
  - `buildArguments` 必含 `exec --json --skip-git-repo-check --ephemeral
    --sandbox read-only -C <tmp>` 和翻译场景禁用的 Codex feature flags，
    且 prompt 始终位于 `--` 终止符之后，防止以 `-` 开头的输入被误判成 flag。
  - `parseCodexError` 同时验证 stderr 兜底（`not signed in`、
    `rate limit`、未知错误）和 stdout JSONL 路径（`turn.failed.error`
    既可能是字符串也可能是 `{message:...}` 对象）。
  - `parseCodexTokenUsage` 验证 `turn.completed.usage` 的扁平字段读取、
    多次 `turn.completed` 取最后一次、空 `usage` 返回 nil。
  - `buildProcessEnvironment` 验证父进程优先、登录 shell allowlist 补齐、
    `PATH` 合并去重、zsh/bash rc source，以及非 allowlist 变量不会进入子进程环境。
  - 工具方法 `runWhich`、`resolveLoginShellPath`、`extractLoginShellEnvironment`、
    `extractCodexText` 覆盖二进制探测、shell 路径回退和 env sentinel 解析。
- `CodexCLIServiceTests.swift` 验证服务的元信息：`serviceType()`、
  `apiKeyRequirement() == .agentCLI`、`isStream() == true`，以及
  `QueryServiceFactory.shared.service(withTypeId:)` 能正确返回
  `CodexCLIService` 实例。

## 测试边界

- 不启动真实子进程，所有 stdout/stderr 都用字符串 fixture 喂给纯函数。
- 不依赖网络或 OpenAI 账号，所以 CI 上和本地行为一致。
- UI 相关流程（设置面板、风险弹窗、Debug 窗口）按项目规范不写测试，
  通过手工验证清单跟踪。

## 排查建议

- CLI 参数或退出码异常 → 先看 runner tests 的 `buildArguments*` 用例。
- Finder/Dock 启动后缺少 API key、access token、`CODEX_HOME`、custom CA 或代理 → 先看
  `buildProcessEnvironment*` 和 `extractLoginShellEnvironment*` 用例。
- 错误未被分类成 `notLoggedIn` / `quotaExceeded` → 给
  `parseCodexError*` 加新的 stdout 或 stderr 用例后再修
  `isCodexAuthenticationMessage` / `isCodexQuotaMessage` 关键字列表。
- token 用量字段为 0 → 检查 `parseCodexTokenUsage` 是否读到了
  `turn.completed.usage`，必要时增加多 turn 场景。
- 服务在设置页消失或注册失败 → 看 service tests 的
  `factoryRegistration`，多半是 `QueryServiceFactory` 注册顺序或
  `EZServiceType` raw value 不一致。

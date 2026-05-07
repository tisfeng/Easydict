# CodexCLI 测试

该目录包含 Codex CLI 服务的单元测试，重点覆盖 CLI 参数构建、
认证与错误解析、token 用量解析以及服务注册。

主要文件如下：
- `CodexCLIRunnerTests.swift`：覆盖 `codex exec --json` 参数构建、
  `stdout`/`stderr` 错误分类、token usage 解析以及登录 shell
  与 `which` 工具方法。
- `CodexCLIServiceTests.swift`：覆盖服务类型、API Key 需求、
  流式能力和工厂注册。

排查建议：
- 认证或 CLI 输出异常优先看 runner tests。
- 服务是否可见、可启用、类型是否正确则看 service tests。

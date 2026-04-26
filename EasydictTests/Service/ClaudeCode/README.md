# ClaudeCode 测试

该目录包含 Claude Code 服务的单元测试，重点覆盖 CLI 参数构建、
认证与错误解析，以及服务注册与基础能力声明。

主要文件如下：
- `ClaudeCodeCLIRunnerTests.swift`：覆盖 `claude` 参数构建、
  `stdout/stderr` 错误分类、token usage 解析，以及
  `~/.claude/settings.json` `env` 的读取逻辑。
- `ClaudeCodeServiceTests.swift`：覆盖服务类型、API Key 需求、
  流式能力和工厂注册。

排查建议：
- 认证或 CLI 输出异常优先看 runner tests。
- 服务是否可见、可启用、类型是否正确则看 service tests。

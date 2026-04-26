# ClaudeCode

该目录实现 Claude Code 翻译服务，并把本地 `claude` CLI 接入
`StreamService` 的流式翻译链路。核心目标是保留 Claude 的认证与代理能力，
同时禁用工具、MCP、插件 hooks 和会话持久化，避免引入额外上下文。

主要组件如下：
- `ClaudeCodeService`：组装翻译 prompt，管理当前 runner 生命周期。
- `ClaudeCodeRunner`：检测 `claude` 可执行文件，注入
  `~/.claude/settings.json` 的 `env`，启动子进程并读取流式输出。
- `ClaudeCodeEventParser`：解析 `stream-json` 事件，区分文本增量、
  登录失败、额度错误和通用 CLI 错误。
- `ClaudeCodeLogger` 与 `ClaudeCodeDebugWindow`：在
  `AGENT_CLI_DEBUG` 下记录和查看原始 CLI 事件。

调试入口：
- 查看 `Application Support/<bundle>/logs/claude-code/*.log`
  确认 CLI 参数、stdout/stderr 和退出码。
- 在设置页的 Claude Code 配置区域检查安装状态与 Debug Log 窗口。

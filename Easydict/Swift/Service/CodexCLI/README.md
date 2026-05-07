# CodexCLI

该目录实现 Codex CLI 翻译服务，并把本地 `codex` CLI 接入
`StreamService` 的流式翻译链路。设计目标与 `ClaudeCode` 保持一致：
保留 OpenAI Codex 自有的认证机制，禁用工具写入与会话持久化，
避免引入额外上下文。

主要组件如下：
- `CodexCLIService`：组装翻译 prompt（system 与对话合并），
  管理当前 runner 生命周期。
- `CodexCLIRunner`：检测 `codex` 可执行文件，启动子进程并读取
  `--json` 输出流。
- `CodexCLIEventParser`：解析 JSONL 事件，区分文本增量
  （`agent_message_delta`）、token 用量（`token_count`）以及
  登录、额度和通用 CLI 错误。
- `CodexCLILogger` 与 `CodexCLIDebugWindow`：在 `AGENT_CLI_DEBUG`
  下记录和查看原始 CLI 事件。

调用参数：
- `codex exec --json --skip-git-repo-check --sandbox read-only -C /tmp -- <prompt>`
- `read-only` 沙箱阻止任何文件写入；`-C /tmp` 避免读取项目级
  `AGENTS.md`；`--json` 让 CLI 输出 JSONL 事件流。

调试入口：
- 查看 `Application Support/<bundle>/logs/codex-cli/*.log`
  确认 CLI 参数、stdout/stderr 和退出码。
- 在设置页的 Codex CLI 配置区域检查安装状态与 Debug Log 窗口。

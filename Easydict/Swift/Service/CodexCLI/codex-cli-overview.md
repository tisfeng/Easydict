# CodexCLI 目录概览

CodexCLI 把本地 `codex` CLI 接入 Easydict 的 `StreamService` 翻译链路。
设计目标与 `ClaudeCode` 一致：保留 OpenAI Codex 自有的认证机制
（`~/.codex/auth.json` 或 `OPENAI_API_KEY`），不做任何 OAuth 或代理绕行；
每次翻译都启动一个独立的 `codex exec --json` 子进程，无跨查询会话状态。

## 关键组件

- `CodexCLIService.swift` 接入 `StreamService` 的 `contentStreamTranslate`
  入口，把系统 prompt 和对话消息合并成单条 prompt（codex 没有独立的
  system prompt 标志），并管理 runner 生命周期。
- `CodexCLIRunner.swift` 通过登录 shell 的 `which codex` 探测二进制路径
  并缓存，用 `Process` 启动子进程并并行读取 stdout / stderr。线程安全的
  `cancel()` 用于在新查询替换或用户取消时立刻终止子进程。
- `CodexCLIEventParser.swift` 解析 JSONL 流式事件：`item.completed`
  （`agent_message`）→ 助手文本，`turn.completed.usage` → token 用量，
  `turn.failed` / `error` → 类型化错误。`error` 字段同时支持字符串和
  `{message,...}` 对象两种结构（Codex 0.128.x 实际行为）。
- `CodexCLIError.swift` 定义 `notInstalled` / `notLoggedIn` /
  `quotaExceeded` / `cliError` 四种错误类型，全部携带本地化文案。
- `CodexCLILogger.swift` 把每次调用的 stdout/stderr/exit code 写入
  `Application Support/<bundle>/logs/codex-cli/`，最多保留 50 个文件。
- `CodexCLIDebugWindow.swift` 仅在 `AGENT_CLI_DEBUG` 编译标记下提供一个
  浮动面板实时显示原始事件，方便调试 CLI 行为变化。

## 主流程

1. `CodexCLIService.contentStreamTranslate` 拼出包含 system + user 内容的
   单条 prompt，构造 `CodexCLIRunner` 并调用 `run(prompt:)`。
2. Runner 在后台 `Task.detached` 中探测二进制并启动子进程，参数为
   `exec --json --skip-git-repo-check --ephemeral --sandbox read-only -C <tmp>`。
3. stdout 按行解析。`item.completed` (`agent_message`) 的文本立刻 yield
   给 `StreamService` 基类，其它事件（`thread.started`、`turn.started`、
   reasoning 等）暂存到控制缓冲区。
4. 子进程退出后，控制缓冲区用于解析 `turn.completed.usage` 与各类失败
   事件。退出码非零且非用户取消时抛出 `CodexCLIError`。
5. 用户取消查询或下一次翻译启动时，`cancel()` 通过原子状态终止子进程，
   onTermination 回调释放管道资源。

## CLI 调用约定

- `--json` 输出 JSONL，每个事件独占一行。
- `--ephemeral` 跳过会话文件持久化，避免污染 `~/.codex/sessions`。
- `--sandbox read-only` 阻止模型工具调用产生文件写入。
- `--skip-git-repo-check` 允许在中性目录（`/tmp`）下执行。
- `-C <tmpdir>` 改变 cwd，避免 codex 读取项目级 `AGENTS.md`。
- 没有 `--system-prompt` 等价物，所以系统指令统一拼进 prompt 文本。
- Codex 0.128.x 不做增量 streaming，整段助手文本一次性出现。

## 调试入口

- 翻译结果异常先看
  `Application Support/<bundle>/logs/codex-cli/*.log` 的退出码和原始事件。
- 设置页 Codex 配置区域显示二进制安装状态；找不到二进制返回
  `notInstalled`。
- `AGENT_CLI_DEBUG` 编译下打开 Debug Log 窗口可实时观察事件流，常用于
  跟踪 codex 版本升级带来的字段变化。
- 错误分类逻辑见
  `parseCodexError(fromStdout:stderr:)`，新错误模式只需扩充关键字列表
  或 `isFailureEvent`。

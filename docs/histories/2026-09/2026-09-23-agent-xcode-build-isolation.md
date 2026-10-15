## 2026-09-23 | 任务：隔离 agent 与 Xcode 的并发编译

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

改进构建与测试规则，要求 agent 编译与 Xcode 编译可以同时进行，即使二者位于同一个本地 dev
空间也互不干扰。

### 变更

- `docs/agents/build-and-test.md` 把并发判据从 `xcodebuild` 命令改为构建目录，并说明 Xcode IDE
  与 `xcodebuild` 共用同一 DerivedData 时的破坏方式。
- 要求 agent 始终显式指定 `-derivedDataPath` 到按 checkout 派生的专用目录，取代原先「默认使用
  Xcode DerivedData、失败才回退临时目录」的规则。
- 常用命令统一使用该专用目录，派生方式内联在命令段，删除独立的 fallback 命令矩阵。
- 补充 `xcodebuild test` 启动 `Easydict-debug.app` 测试宿主时的进程级并发限制。

### 设计意图

Xcode IDE 与 `xcodebuild` 的冲突来源是同一 DerivedData 中的增量状态和 build database，而不是
构建入口本身。把 agent 固定到与 Xcode 默认目录不相交、且按 checkout 稳定复用的目录后，两者可以
在同一个 checkout 上并发编译，同时保留各自的增量构建。原先「默认目录加失败回退」的写法只把临时
目录当作故障恢复手段，没有覆盖并发场景，因此由专用目录规则替代。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath
  ~/Library/Developer/Xcode/DerivedData/Easydict-Agent/codex_worktrees_80b0_Easydict`：通过，
  首次全量构建产出 `Build/Products/Debug/Easydict-debug.app`。
- 隔离证据：该次构建期间 Xcode 默认 DerivedData `Easydict-entaqaylceybfqboqggmsizyhose` 没有
  任何被写入的顶层条目，mtime 保持 02:33:20；agent 专用目录占用 5.6 GB。
- `git diff --check`：通过；新增行宽全部 ≤100 显示列。
- review：未运行，本次只修改仓库治理 Markdown。
- 未验证 Xcode IDE 与 agent 同时构建的端到端场景。

### 受影响文件

- `docs/agents/build-and-test.md`
- `docs/histories/2026-09/2026-09-23-agent-xcode-build-isolation.md`

### 后续事项

- 专用 DerivedData 按 checkout 各占一份全量缓存，磁盘占用明显上升；可在磁盘紧张时清理
  `~/Library/Developer/Xcode/DerivedData/Easydict-Agent/` 下不再使用的 checkout 目录。
- 测试宿主进程的 bundle id 冲突尚未解决，因此测试仍要求与 Xcode 的 Run/Test 串行。

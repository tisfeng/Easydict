## 2026-09-23 | 任务：精简构建与测试规则

**Links:** None

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

构建与测试规则过于啰嗦，要求整理简化并保持清晰；命令保留一个参数一行的写法，不为省行数合并
参数，`.serialized` 的说明保留在本文。

### 变更

- `docs/agents/build-and-test.md` 由 6 个小节收敛为 4 个：合并「测试目录与文件组织」与「工程文件
  与资源」为「测试与工程文件组织」，合并「选择 Xcode 验证」与「非 Xcode 检查」为「选择验证」。
- 消除重复条款：治理 Markdown 的静态检查原先分散在两节，现只保留一处；测试授权由三条并为两条。
- 常用命令由 5 个命令块减为 4 个，suite 与单方法两条合并为一条，并在注释说明 `-only-testing`
  支持 `<Suite>` 与 `<Suite>/<test>`；`-workspace`、`-scheme`、`-derivedDataPath` 仍各占一行。
- 删除「见下节」等转场句和 fallback 说明中的重复表述。

### 设计意图

原文的冗余来自同一条约束分散在多节、以及同一命令的多个近似副本，而不是约束本身过多。因此按
「同一条约束只出现一次」合并小节与条目，同时保留一个参数一行的命令格式，使命令可以直接复制而
不需要重新断行。测试授权、目录映射、工程引用同步、验证选择、DerivedData 隔离和测试宿主串行等
约束一条未减。

### 验证

- 行宽检查：全文正文与代码注释均 ≤100 显示列。
- 规模变化：`docs/agents/build-and-test.md` 从 111 行降到 84 行。
- 语义复核：旧版 23 条列表项与 1 段工程引用说明逐条比对，全部归入新版 14 条列表项。
- 引用检查：全仓库没有指向本文锚点的链接，小节改名与合并未产生失效链接；文中引用的
  `EasydictTests/Support/`、`Easydict.xcodeproj/project.pbxproj` 均存在。
- `git diff --check`：通过。
- review：未运行，本次只修改仓库治理 Markdown。
- `xcodebuild`：未运行，本任务不涉及源码、工程文件或运行时资源。

### 受影响文件

- `docs/agents/build-and-test.md`
- `docs/histories/2026-09/2026-09-23-simplify-build-test-rules.md`

### 后续事项

- None
